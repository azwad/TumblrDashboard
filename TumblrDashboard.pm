#!/usr/bin/perl
use strict;
use warnings;
use URI;
use WWW::Mechanize::GZip;
use YAML;
use Encode qw( decode_utf8);
use Config::Pit;
use Compress::Zlib;
use XML::Simple;
use feature qw( say );

{ package TumblrDashboard;
	sub new {
		my $proto = shift;
		my $class = ref $proto || $proto;
		my $self = {};
		bless $self, $class;
		$self->pit_account(shift);
		$self->set_option( @_ );
		return $self;
	}
	sub pit_account {
		my $self = shift;
		if ( @_ ) {
			$self->{pit_account} = $_[0];
			$self->init;
		}
		return $self->{pit_account};
	}	
	sub set_option {
		my ( $self, %args ) = @_;
		if ( @_) {
			$self->{option} = { %args };
			$self->init_option;
		}
		return $self->{option};
	}
	sub init_option {
		my $self = shift;
		my $option = $self->{option};
		my @options =( );
		push(@options,  ('&start='.$option->{start}))			if $option->{start}; 
		push(@options,  ('&num='. $option->{num}))				if $option->{num};
		push(@options,  ('&type='. $option->{type}))			if $option->{type};
		push(@options,  ('&filter='. $option->{filter}))	if $option->{filter};
		push(@options,  ('&likes=' . $option->{likes}))		if $option->{likes};
		$self->{init_option} = join('',@options);
		$self->init;
		return  $self->{init_option};
	}
	sub init {
		my $self = shift;
		my $apiurl = 'http://www.tumblr.com/api/dashboard';
		if ( $self->{option}->{liked}){
			my $liked =  $self->{option}->{liked};
			if  ($liked eq 'true'){
				$apiurl = 'http://www.tumblr.com/api/likes';
			}
		}

#		print "Access API is $apiurl\n";
		my $pit_account;
		if ( $self->{pit_account}){
			$pit_account = $self->{pit_account};
		}
		else{
			return print "Set pit_account\n";
		}
		my $config = Config::Pit::pit_get($pit_account, require => {
				"user"		 => "username",
				"email"		 => "email address",
				"password" => "password"
				}
		);
		my $email = $config->{email};
		my $password = $config->{password};
		my $url = $apiurl."?email=" . $email . "&password=". $password;
		$url 	= $url. $self->{init_option} if $self->{init_option};
		$self->{uri} = URI->new($url);
		return;
	}
	sub get {
		my $self = shift;
		my $dashboard = WWW::Mechanize::GZip->new();
		my $result= $dashboard->get($self->{uri});
		my $content_xml = $result->{_content};
		Encode::decode_utf8($content_xml);
		my $xs = XML::Simple->new();
		return  $self->{content_data} = $xs->XMLin($content_xml);
	}
	sub get_hash {
		my $self = shift;
		my $content_data;
		if ($self->{content_data} ){
			$content_data = $self->{content_data};
		}
		else{
			$content_data = $self->get();
		}
		unless (exists $content_data->{posts}->{post}) {
			print "no contents data\n";
			return $self->{err} = 1;
		}
		for my $post ($content_data->{posts}) {
			while( my ($keys, $values)= each $post->{post}){
				while (my ($keys2, $values2) = each $values) {
				$self->{posts}->{$keys}->{$keys2} = $values2;
 				}
			}
		}
		$self->{err} = 0;
		return $self->{posts};
	}
	sub _err {
		my $self = shift;
		return $self->{err} || 0;
	}
}

1;


