package WebService::Braintree::UsBankAccountGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

has 'gateway' => (is => 'ro');

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    $self->_make_request("/payment_methods/us_bank_account/$token", "get", undef)->us_bank_account;
}

__PACKAGE__->meta->make_immutable;

1;
__END__