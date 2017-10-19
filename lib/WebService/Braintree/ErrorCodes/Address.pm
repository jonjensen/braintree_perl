# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Address;

use 5.010_001;
use strictures 1;

use constant CannotBeBlank                   => "81801";
use constant CompanyIsInvalid                => "91821";
use constant CompanyIsTooLong                => "81802";
use constant CountryCodeAlpha2IsNotAccepted  => "91814";
use constant CountryCodeAlpha3IsNotAccepted  => "91816";
use constant CountryCodeNumericIsNotAccepted => "91817";
use constant CountryNameIsNotAccepted        => "91803";
use constant ExtendedAddressIsInvalid        => "91823";
use constant ExtendedAddressIsTooLong        => "81804";
use constant FirstNameIsInvalid              => "91819";
use constant FirstNameIsTooLong              => "81805";
use constant InconsistentCountry             => "91815";
use constant LastNameIsInvalid               => "91820";
use constant LastNameIsTooLong               => "81806";
use constant LocalityIsInvalid               => "91824";
use constant LocalityIsTooLong               => "81807";
use constant PostalCodeInvalidCharacters     => "81813";
use constant PostalCodeIsInvalid             => "91826";
use constant PostalCodeIsRequired            => "81808";
use constant PostalCodeIsTooLong             => "81809";
use constant RegionIsInvalid                 => "91825";
use constant RegionIsTooLong                 => "81810";
use constant StreetAddressIsInvalid          => "91822";
use constant StreetAddressIsRequired         => "81811";
use constant StreetAddressIsTooLong          => "81812";
use constant TooManyAddressesPerCustomer     => "91818";

1;
__END__
