# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper qw(sandbox);

my $customer_create = WebService::Braintree::Customer->create({
    first_name => "Walter",
    last_name => "Weatherman",
});

subtest "Searches text and partial match and equality fields" => sub {
    my $cardholder_name = "Tom Smith" . generate_unique_integer();
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "4000111111111115",
        expiration_date => "12/15",
        cardholder_name => $cardholder_name,
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    my $verification = $result->credit_card_verification;

    my $search_results = WebService::Braintree::CreditCardVerification->search(sub {
        my $search = shift;
        $search->id->is($verification->id);
        $search->credit_card_cardholder_name->is($cardholder_name);
        $search->credit_card_number->is("4000111111111115");
        $search->credit_card_expiration_date->is("12/15");
    });

    is $search_results->maximum_size, 1;
    is $search_results->first->credit_card->{'cardholder_name'}, $cardholder_name;
    is $search_results->first->credit_card->{'expiration_year'}, "2015";
    is $search_results->first->credit_card->{'expiration_month'}, "12";
    is $search_results->first->credit_card->{'bin'}, "400011";
    is $search_results->first->credit_card->{'last_4'}, "1115";
};

subtest "Searches multiple value fields" => sub {
    my $visa_credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "4000111111111115",
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($visa_credit_card_params);
    my $first_verification = $result->credit_card_verification;

    my $mastercard_credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "5105105105105100",
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    $result = WebService::Braintree::CreditCard->create($mastercard_credit_card_params);
    my $second_verification = $result->credit_card_verification;

    my $search_results = WebService::Braintree::CreditCardVerification->search(sub {
        my $search = shift;
        $search->ids->in($first_verification->id, $second_verification->id);
        $search->credit_card_card_type->in([
            WebService::Braintree::CreditCard::CardType::Visa,
            WebService::Braintree::CreditCard::CardType::MasterCard,
        ]);
    });

    is $search_results->maximum_size, 2;

    $search_results = WebService::Braintree::CreditCardVerification->search(sub {
        my $search = shift;
        $search->ids->in($first_verification->id);
        $search->credit_card_card_type->in(
            WebService::Braintree::CreditCard::CardType::MasterCard
        );
    });

    is $search_results->maximum_size, 0;

    $search_results = WebService::Braintree::CreditCardVerification->search(sub {
        my $search = shift;
        $search->ids->in($second_verification->id);
        $search->credit_card_card_type->in(
            WebService::Braintree::CreditCard::CardType::MasterCard
        );
    });

    is $search_results->maximum_size, 1;
    is $search_results->first->credit_card->{'card_type'}, WebService::Braintree::CreditCard::CardType::MasterCard;
};

subtest "Searches fail on invalid credit card types" => sub {
    should_throw "Invalid Argument\\(s\\) for credit_card_card_type: invalid credit_card_card_type", sub {
        my $search_result = WebService::Braintree::CreditCardVerification->search(sub {
            my $search = shift;
            $search->credit_card_card_type->is("invalid credit_card_card_type");
        });
    }
};

subtest "Searches range fields" => sub {
    my $cardholder_name = "Tom Smith" . generate_unique_integer();
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "4000111111111115",
        expiration_date => "12/15",
        cardholder_name => $cardholder_name,
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    my $verification = $result->credit_card_verification;

    my $before = $verification->created_at - DateTime::Duration->new(minutes => 1);
    my $after  = $verification->created_at + DateTime::Duration->new(minutes => 1);

    my $search_results = WebService::Braintree::CreditCardVerification->search(sub {
        my $search = shift;
        $search->credit_card_cardholder_name->is($cardholder_name);
        $search->created_at->between($before, $after);
    });

    is $search_results->maximum_size, 1;
    is $search_results->first->credit_card->{'cardholder_name'}, $cardholder_name;

    $search_results = WebService::Braintree::CreditCardVerification->search(sub {
        my $search = shift;
        $search->credit_card_cardholder_name->is($cardholder_name);
        $search->created_at->min($after);
    });

    is $search_results->maximum_size, 0;
};

subtest "gets all ccvs" => sub {
    my $ccvs = WebService::Braintree::CreditCardVerification->all;
    ok scalar @{$ccvs->ids} > 1;
};

done_testing();
