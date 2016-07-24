use strict;
use warnings;
use Plack::Test;
use Test::More tests => 2;
use HTTP::Request;
use HTTP::Request::Common;
{
    package CalculatorImplementation;
    use Moo;
    use XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation;
    with 'XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation';

    sub soapaction_add {
        my ( $self, $soap, $data, $dsl ) = @_;
        return +{
            Result => $data->{parameters}->{x} + $data->{parameters}->{y},
        };
    }

    no Moo;
}
{
    package Custom;
    use Dancer2;
    use XML::Compile::SOAP::Daemon::Dancer2;;

    wsdl_endpoint '/calculator', {
        wsdl                    => 'calculator.wsdl',
        xsd                     => [],
        implementation_class    => 'CalculatorImplementation',
    };
}

my $app = Custom->to_app;
my $test = Plack::Test->create($app);

open my $fh, '<', "t/wsdl/calculator.wsdl"  or die;
$/ = undef;
my $data = <$fh>;
close $fh;
my $response = $test->request( GET "/calculator?wsdl" );
is $response->content, $data, "Wsdl retrieved correclty";

my $request = HTTP::Request->parse( <<EOR );
POST /calculator
Content-Type: text/xml; charset=utf-8
SOAPAction: "add"

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Body>
    <tns:add xmlns:tns="http://www.parasoft.com/wsdl/calculator/">
      <tns:x>4</tns:x>
      <tns:y>5</tns:y>
    </tns:add>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOR


$response = $test->request( $request )->content;
is $response, <<EOResponse, "Response is correct";
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Body><tns:addResponse xmlns:tns="http://www.parasoft.com/wsdl/calculator/"><tns:Result>9</tns:Result></tns:addResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
EOResponse
