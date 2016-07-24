package XML::Compile::SOAP::Daemon::Dancer2::Handler;
use warnings;
use strict;
use vars '$VERSION';
$VERSION = '0.1';

use parent 'XML::Compile::SOAP::Daemon';

use Log::Report 'xml-compile-soap-daemon';
use Encode;


use constant
  { RC_OK                 => 200
  , RC_METHOD_NOT_ALLOWED => 405
  , RC_NOT_ACCEPTABLE     => 406
  , RC_SERVER_ERROR       => 500
  };

#--------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->_init($args);
    $self;
}

#------------------------------

sub _init($)
{   my ($self, $args) = @_;
    $self->{preprocess}  = $args->{preprocess};
    $self->{postprocess} = $args->{postprocess};
    $self;
}


# PSGI request handler
#will be called from the route
#sub call($)
#{   my ($self, $env) = @_;
    #my $res = eval { $self->_call($env) };
    #$res ||= Plack::Response->new
      #( RC_SERVER_ERROR
      #, [Content_Type => 'text/plain']
      #, [$@]
      #);
    #$res->finalize;
#}

sub handle($)
{   my ($self, $dsl) = @_;

    notice __x"WSA module loaded, but not used"
        if XML::Compile::SOAP::WSA->can('new') && !keys %{$self->{wsa_input}};
    $self->{wsa_input_rev}  = +{ reverse %{$self->{wsa_input}} };

    #return $self->sendWsdl($req)
        #if $req->method eq 'GET' && uc($req->uri->query || '') eq 'WSDL';

    my $method = $dsl->request->method;
    my $ct     = $dsl->request->content_type || 'text/plain';
    $ct =~ s/\;\s.*//;

    my ($rc, $msg, $err, $content, $mime);
    if($method ne 'POST' && $method ne 'M-POST')
    {   ($rc, $msg) = (RC_METHOD_NOT_ALLOWED, 'only POST or M-POST');
        $err = 'attempt to connect via GET';
    }
    elsif($ct !~ m/\bxml\b/)
    {   ($rc, $msg) = (RC_NOT_ACCEPTABLE, 'required is XML');
        $err = 'content-type seems to be '.$ct.', must be some XML';
    }
    else
    {   my $charset = $dsl->request->headers->content_type_charset || 'ascii';
        my $xmlin   = decode $charset, $dsl->request->content;
        my $action  = $dsl->request->header('SOAPAction') || '';
        $action     =~ s/["'\s]//g;   # sometimes illegal quoting and blanks "
        ($rc, $msg, my $xmlout) = $self->process(\$xmlin, $dsl, $action);
        #($rc, $msg, my $xmlout) = (RC_OK, 'blab', XML::LibXML::Document->createDocument() );
        #($rc, $msg, my $xmlout) = (RC_OK, 'blab', 'pppp' );

        if(UNIVERSAL::isa($xmlout, 'XML::LibXML::Document'))
        {   $content = $xmlout->toString($rc == RC_OK ? 0 : 1);
            $mime  = 'text/xml; charset="utf-8"';
        }
        else
        {
            $err   = $xmlout;
        }
    }

    if( $err ) {
        $content = $err;#            $bytes = "[$rc] $err\n";
        $mime  = 'text/plain';
    }
    $dsl->status( $rc );
    $dsl->content_type( $mime );
    $dsl->header( Warning => "199 $msg" ) if length( $msg );
    #$dsl->content_length(length $bytes);
    return $content;
}

#manage from the route itself
#sub setWsdlResponse($;$)
#{   my ($self, $fn, $ft) = @_;
    #local *WSDL;
    #open WSDL, '<:raw', $fn
        #or fault __x"cannot read WSDL from {file}", file => $fn;
    #local $/;
    #$self->{wsdl_data} = <WSDL>;
    #$self->{wsdl_type} = $ft || 'application/wsdl+xml';
    #close WSDL;
#}

#sub sendWsdl($)
#{   my ($self, $req) = @_;

    #my $res = $req->new_response(RC_OK,
      #{ Warning        => '199 WSDL specification'
      #, Content_Type   => $self->{wsdl_type}.'; charset=utf-8'
      #, Content_Length => length($self->{wsdl_data})
      #}, $self->{wsdl_data});

    #$res;
#}

#-----------------------------

1;


1;
