package Data::FormValidator::Constraints::DateTime;
use strict;
use DateTime;
use DateTime::Format::Strptime;

our $VERSION = '0.06';

=head1 NAME

Data::FormValidator::Constraints::DateTime - D::FV constraints for dates and times

=head1 DESCRIPTION

This package provides constraint routines for Data::FormValidator for
dealing with dates and times. It provides an easy mechanism for validating
dates of any format (using strptime(3)) and transforming those dates (as long
as you 'untaint' the fields) into valid L<DateTime> objects, or into strings 
that would be properly formatted for various database engines.

=head1 ABSTRACT

  use Data::FormValidator;
    
  # create our profile
  my $profile = {
      validator_packages      => [qw(Data::FormValidator::Constraints::DateTime)],
      required                => [qw(my_date)],
      constraints             => {
          # my_date is in the format MM/DD/YYYY
          my_date   => {
            constraint_method   => 'to_datetime',
            params              => [\'%D'], # some valid strptime format string
          },
      },
      untaint_all_constraints => 1,
  };

  # validate 'my_date'
  my $results = Data::FormValidator->check($my_input, $profile);

  unless( $results->has_missing || $results->has_invalid ) {
    # if we got here then $results->valid('my_date')
    # is a valid DateTime object 
    my $datetime = $results->valid('my_date');
    .
    .
  }

=head1 STRPTIME FORMATS

Most of the validation routines provided by this module use
strptime(3) format strings to know what format your date string
is in before we can process it. You specify this format for each
date you want to validate using the 'params' array ref (see the
example above).

We use L<DateTime::Format::Strptime> for this transformation. 
If you need a list of these formats (if you haven't yet committed 
them to memory) you can see the strptime(3) man page (if you are 
on a *nix system) or you can see the L<DateTime::Format::Strptime> 
documentation.

There are however some routines that can live without the format
param. These include routines which try and validate according
to rules for a particular database (C<< to_mysql_* >> and 
C<< to_pg_* >>). If no format is provided, then we will attempt to
validate according to the rules for that datatype in that database
(using L<DateTime::Format::MySQL> and L<DateTime::Format::Pg>).
Here are some examples:

without a format param

 my $profile = {
   validator_packages      => [qw(Data::FormValidator::Constraints::DateTime)],
   required                => [qw(my_date)],
   constraints             => {
       my_date => 'to_mysql_datetime',
   },
 };

with a format param

 my $profile = {
   validator_packages      => [qw(Data::FormValidator::Constraints::DateTime)],
   required                => [qw(my_date)],
   constraints             => {
       my_date => {
         constraint_method => 'to_mysql_datetime',
         params            => [\'%m/%d/%Y'],
   },
 };


=head1 VALIDATION ROUTINES

Following is the list of validation routines that are provided
by this module.

=head2 to_datetime

The routine will validate the date aginst a strptime(3) format and
change the date string into a DateTime object. This
is the only routine that B<must> have an accompanying format param.

=cut

sub match_to_datetime {
    my ($self, $format) = @_;
    # if $self is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $self ? $self->get_current_constraint_value : $self;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    return $dt;
}

sub _get_datetime_from_strp {
    my ($value, $format) = @_;
    $format = $$format;
    # create the formatter
    my $formatter = DateTime::Format::Strptime->new(
        pattern => $format
    );
    my $dt;
    # create the DateTime object
    eval { $dt = $formatter->parse_datetime($value); };
    $dt->set_formatter($formatter)
        if( $dt );
    return $dt;
}

=head2 ymd_to_datetime

This routine is used to take multiple inputs (one each for the
year, month, and day) and combine them into a L<DateTime> object,
validate the resulting date, and give you the resulting DateTime
object in your C<< valid() >> results. It must recieve as C<< params >>
the year, month, and day inputs in that order. You may also specify
additional C<< params >> that will be interpretted as 'hour', 'minute'
and 'second' values to use. If none are provided, then the time '00:00:00'
will be used.

 my $profile = {
   validator_packages      => [qw(Data::FormValidator::Constraints::DateTime)],
   required                => [qw(my_year)],
   constraints             => {
      my_year => {
        constraint_method => 'ymd_to_datetime',
                             # my_hour, my_min, and my_sec are optional
        params            => [qw(my_year my_month my_day my_hour my_min my_sec)],
      },
   },
   untaint_all_constraints => 1,
 };
 my $results = Data::FormValidator->check($data, $profile);

 #if the date was valid, then we how have a DateTime object
 my $datetime = $results->valid('my_year');

=cut

sub match_ymd_to_datetime {
    my $self = shift;
    my ($year, $month, $day, $hour, $min, $sec);
    # if we were called as a 'constraint_method'
    if( ref $self ) {
        ($year, $month, $day, $hour, $min, $sec) = @_;
    # else we were called as a 'constraint'
    } else {
        ($year, $month, $day, $hour, $min, $sec) = ($self, @_);
    }
    # make sure year, month and day are positive numbers
    if( 
        defined $year && $year ne "" 
        && defined $month && $month ne "" 
        && defined $day && $day ne "" 
    ) {
        # set the defaults for time if we don't have any
        $hour ||= 0;
        $min  ||= 0;
        $sec  ||= 0;
    
        my $dt;
        eval {
            $dt = DateTime->new(
                year    => $year,
                month   => $month,
                day     => $day,
                hour    => $hour,
                minute  => $min,
                second  => $sec,
            );
        };
        return $dt;
    } else {
        return;
    }
}

=head1 DATABASE VALIDATION ROUTINES

=head2 to_mysql_datetime

The routine will change the date string into a DATETIME datatype
suitable for MySQL. If you don't provide a format parameter then
this routine will just validate the data as a valid MySQL DATETIME
datatype (using L<DateTime::Format::MySQL>).

=cut

sub match_to_mysql_datetime {
    my ($self, $format) = @_;
    # if $self is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $self ? $self->get_current_constraint_value : $self;

    # make sure they have DateTime::Format::MySQL
    eval { require DateTime::Format::MySQL; };
    die "DateTime::Format::MySQL is required to use this routine"
        if( $@ );
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( ref $format eq 'SCALAR' ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so just use parse_datetime
    } else {
        eval { $dt = DateTime::Format::MySQL->parse_datetime($value) };
    }
    if( $dt ) {
        return DateTime::Format::MySQL->format_datetime($dt); 
    } else {
        return undef;
    }
}

=head2 to_mysql_date

The routine will change the date string into a DATE datatype
suitable for MySQL. If you don't provide a format param then
this routine will validate the data as a valid DATE datatype
in MySQL (using L<DateTime::Format::MySQL>).

=cut

sub match_to_mysql_date {
    my ($self, $format) = @_;
    # if $self is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $self ? $self->get_current_constraint_value : $self;

    # make sure they have DateTime::Format::MySQL
    eval { require DateTime::Format::MySQL; };
    die "DateTime::Format::MySQL is required to use this routine"
        if( $@ );
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( ref $format eq 'SCALAR' ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so just use parse_datetime
    } else {
        eval { $dt = DateTime::Format::MySQL->parse_date($value) };
    }
    if( $dt ) {
        return DateTime::Format::MySQL->format_date($dt);
    } else {
        return undef;
    }
}

=head2 to_mysql_timestamp

The routine will change the date string into a TIMESTAMP datatype
suitable for MySQL. If you don't provide a format then the data
will be validated as a MySQL TIMESTAMP datatype.

=cut

sub match_to_mysql_timestamp {
    my ($self, $format) = @_;
    # if $self is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $self ? $self->get_current_constraint_value : $self;
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( ref $format eq 'SCALAR' ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so parse into a timestamp
    } else {
        # if it matches a timestamp format YYYYMMDDHHMMSS
        # but we're actually a little looser than that... we take
        # YYYY-MM-DD HH:MM:SS with any other potential separators
        if( $value =~ /(\d{4})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})/ ) {
            eval { 
                $dt = DateTime->new(
                    year    => $1,
                    month   => $2,
                    day     => $3,
                    hour    => $4,
                    minute  => $5,
                    second  => $6,
                );
            };
        }
    }
    if( $dt ) {
        return $dt->ymd('') . $dt->hms('');
    } else {
        return undef;
    }
}

=head2 to_pg_datetime

The routine will change the date string into a DATETIME datatype
suitable for PostgreSQL. If you don't provide a format then the
data will validated as a DATETIME datatype in PostgresSQL (using
L<DateTime::Format::Pg>).

=cut

sub match_to_pg_datetime {
    my ($self, $format) = @_;
    # if $self is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $self ? $self->get_current_constraint_value : $self;

    # make sure they have DateTime::Format::MySQL
    eval { require DateTime::Format::Pg; };
    die "DateTime::Format::Pg is required to use this routine"
        if( $@ );
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( ref $format eq 'SCALAR' ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so just use parse_datetime
    } else {
        eval { $dt = DateTime::Format::Pg->parse_datetime($value) };
    }
    if( $dt ) {
        return DateTime::Format::Pg->format_datetime($dt);
    } else {
        return undef;
    }
}


=head1 AUTHOR

Michael Peters <mpeters@plusthree.com>

Thanks to Plus Three, LP (http://www.plusthree.com) for sponsoring my work on this module

=head1 CONTRIBUTORS

=over 

=item Mark Stosberg <mark@summersault.com>

=item Charles Frank <cfrank@plusthree.com>

=back

=head1 SUPPORT

This module is a part of the larger L<Data::FormValidator> project. If you have
questions, comments, bug reports or feature requests, please join the 
L<Data::FormValidator>'s mailing list.

=head1 SEE ALSO

L<Data::FormValidator>, L<DateTime>. L<DateTime::Format::Strptime>,
L<DateTime::Format::MySQL>, L<DateTime::Format::Pg>

