# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use JSON;
use MIME::Base64;
use WebService::Braintree;
use WebService::Braintree::ClientToken;
use WebService::Braintree::Test;
use WebService::Braintree::TestHelper qw(sandbox);
use WebService::Braintree::ClientApiHTTP;

subtest "Generate a fingerprint that the gateway accepts" => sub {
    my $client_token = decode_json(
        WebService::Braintree::TestHelper::generate_decoded_client_token()
    );
    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};
    my $config = WebService::Braintree::TestHelper->config;

    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => "fake_identifier",
        shared_customer_identifier_type => "testing",
    );

    my $result = $http->get_cards();
    validate_result($result) or return;
};

subtest "it allows a client token version to be specified" => sub {
    my $client_token = decode_json(
        WebService::Braintree::ClientToken->generate({
            version => 1,
        })
    );
    ok $client_token->{"version"} == 1;
};

subtest "it can pass verify card" => sub {
    my $config = WebService::Braintree::TestHelper->config;
    my $customer = WebService::Braintree::Customer->create()->customer();

    my $client_token = decode_json(
        WebService::Braintree::TestHelper::generate_decoded_client_token({
            customer_id => $customer->id,
            options => {
                verify_card => 1,
            },
        })
    );
    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};

    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => "fake_identifier",
        shared_customer_identifier_type => "testing",
    );

    my $result = $http->add_card({
        credit_card => {
            number => "4000111111111115",
            expiration_date => "11/2099",
        },
    });
    ok $result->code == 422;
    my $response = from_json($result->content);
    ok $response->{"error"}->{"message"} eq "Credit card verification failed";
};

subtest "it can pass make default" => sub {
    my $config = WebService::Braintree::TestHelper->config;
    my $customer = WebService::Braintree::Customer->create()->customer();

    my $client_token = decode_json(
        WebService::Braintree::TestHelper::generate_decoded_client_token({
            customer_id => $customer->id,
            options => {
                make_default => 1,
            },
        })
    );
    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};

    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => "fake_identifier",
        shared_customer_identifier_type => "testing",
    );

    my $cc_number = cc_number();
    my $result = $http->add_card({
        credit_card => {
            number => $cc_number,
            expiration_date => "11/2098",
        },
    });
    ok $result->code == 201;

    $result = $http->add_card({
        credit_card => {
            number => $cc_number,
            expiration_date => "11/2099",
        },
    });
    ok $result->code == 201;

    my $found_customer = WebService::Braintree::Customer->find($customer->id);

    foreach my $card (@{$found_customer->credit_cards}) {
        if ($card->is_default) {
            is($card->expiration_year, "2099");
        }
    }
};

subtest "it defaults to version 2" => sub {
    my $encoded_client_token = WebService::Braintree::ClientToken->generate();
    my $decoded_client_token = decode_json(
        decode_base64($encoded_client_token)
    );
    my $version = $decoded_client_token->{"version"};
    is($version, 2);
};

subtest "it can pass fail_on_duplicate_payment_method card" => sub {
    my $config = WebService::Braintree::TestHelper->config;
    my $customer = WebService::Braintree::Customer->create()->customer();
    my $client_token = decode_json(
        WebService::Braintree::TestHelper::generate_decoded_client_token({
            customer_id => $customer->id,
        })
    );
    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};

    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => "fake_identifier",
        shared_customer_identifier_type => "testing",
    );

    my $cc = credit_card();

    my $result = $http->add_card({
        credit_card => $cc,
    });
    ok $result->code == 201;

    $client_token = decode_json(
        WebService::Braintree::TestHelper::generate_decoded_client_token({
            customer_id => $customer->id,
            options => {
                fail_on_duplicate_payment_method => 1,
            },
        })
    );
    $authorization_fingerprint = $client_token->{'authorizationFingerprint'};
    $http->fingerprint($authorization_fingerprint);

    $result = $http->add_card({
        credit_card => $cc,
    });
    ok $result->code == 422;
    my $response = from_json($result->content);
    ok $response->{"fieldErrors"}[0]->{"fieldErrors"}[0]->{"message"} eq "Duplicate card exists in the vault";
};

subtest "client token accepts merchant account id" => sub {
    my $client_token = decode_json(
        WebService::Braintree::TestHelper::generate_decoded_client_token({
            merchant_account_id => "merchant_account_id",
        })
    );

    ok $client_token->{merchantAccountId} eq "merchant_account_id";
};

done_testing();
