requires 'perl', '5.008005';

requires 'Dancer2';
requires 'XML::Compile::SOAP';
requires 'XML::Compile::WSDL11';
requires 'XML::Compile::SOAP::Daemon';

on test => sub {
    requires 'Test::More', '0.96';
};
