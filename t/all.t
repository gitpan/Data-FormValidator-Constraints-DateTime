use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
plan(tests => 47);

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import();
my $format          = '%m-%d-%Y';
my $good_date       = '02-17-2005';
my $unreal_date     = '02-31-2005';
my $bad_date        = '0-312-005';
my $real_bad_date   = '2';
my @inputs          = qw(good bad realbad unreal);
my $profile         = {
    validator_packages      => ['Data::FormValidator::Constraints::DateTime'], 
    required                => \@inputs,
    untaint_all_constraints => 1,
    debug                   => 1,
};
my $DATA            = {
    good    => $good_date,
    unreal  => $unreal_date,
    bad     => $bad_date,
    realbad => $real_bad_date,
};
my ($results, $date);

# 2..7
# to_datetime
{
    $profile->{constraints} = _make_constraints('to_datetime');
    $results = Data::FormValidator->check($DATA, $profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    ok( $results->invalid('realbad'), 'datetime expected invalid');
    ok( $results->invalid('unreal'), 'datetime expected invalid');
    $date = $results->valid('good');
    isa_ok( $date, 'DateTime');
    is( "$date", $good_date, 'DateTime stringifies correctly');
};


# test to see if we have DateTime::Format::MySQL
my $HAVE_DT_FORMAT_MYSQL = 0;
eval { require DateTime::Format::MySQL };
$HAVE_DT_FORMAT_MYSQL = 1 if( !$@ );

SKIP: {
    skip('DateTime::Format::MySQL not installed', 9)
        unless $HAVE_DT_FORMAT_MYSQL;

    # 8..17
    # to_mysql_datetime
    {
        # with params and without
        foreach my $without_params (0,1) {
            $profile->{constraints} = _make_constraints('to_mysql_datetime', $without_params);
            my %data = %$DATA;
            $data{good} = '2005-02-17 00:00:00' if( $without_params );
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'mysql_datetime expected valid');
            ok( $results->invalid('bad'), 'mysql_datetime expected invalid');
            ok( $results->invalid('realbad'), 'mysql_datetime expected invalid');
            ok( $results->invalid('unreal'), 'mysql_datetime expected invalid');
            $date = $results->valid('good');
            is($date, '2005-02-17 00:00:00', 'mysql_datetime correct format');
        }
    }
    
    # 18..27
    # to_mysql_date
    {
        # with params and without
        foreach my $without_params (0,1) {
            $profile->{constraints} = _make_constraints('to_mysql_date', $without_params);
            my %data = %$DATA;
            $data{good} = '2005-02-17' if( $without_params );
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'mysql_date expected valid');
            ok( $results->invalid('bad'), 'mysql_date expected invalid');
            ok( $results->invalid('realbad'), 'mysql_date expected invalid');
            ok( $results->invalid('unreal'), 'mysql_date expected invalid');
            $date = $results->valid('good');
            is($date, '2005-02-17', 'mysql_date correct format');
        }
    }
    
    # 28..37
    # to_mysql_timestamp
    {
        foreach my $without_params (0,1) {
            $profile->{constraints} = _make_constraints('to_mysql_timestamp', $without_params);
            my %data = %$DATA;
            $data{good} = '20050217000000' if( $without_params );
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'mysql_timestamp expected valid');
            ok( $results->invalid('bad'), 'mysql_timestamp expected invalid');
            ok( $results->invalid('realbad'), 'mysql_timestamp expected invalid');
            ok( $results->invalid('unreal'), 'mysql_timestamp expected invalid');
            my $date = $results->valid('good');
            is($date, '20050217000000', 'mysql_timestamp correct format');
        }
    }
}

# test to see if we have DateTime::Format::Pg
my $HAVE_DT_FORMAT_PG = 0;
eval { require DateTime::Format::Pg };
$HAVE_DT_FORMAT_PG = 1 if( !$@ );

SKIP: {
    skip('DateTime::Format::Pg not installed', 3)
        unless $HAVE_DT_FORMAT_PG;
    # 38..47
    # to_pg_datetime
    {
        foreach my $without_params (0,1) {
            $profile->{constraints} = _make_constraints('to_pg_datetime', $without_params);
            my %data = %$DATA;
            $results = Data::FormValidator->check(\%data, $profile);
            ok( $results->valid('good'), 'pg_datetime expected valid');
            ok( $results->invalid('bad'), 'pg_datetime expected invalid');
            ok( $results->invalid('realbad'), 'pg_datetime expected invalid');
            ok( $results->invalid('unreal'), 'pg_datetime expected invalid');
            my $date = $results->valid('good');
            like($date, qr/2005-02-17 00:00:00(\.000000000\+0000)?/, 'pg_datetime correct format');
        }
    }
}


sub _make_constraints {
    my $method = shift;
    my $no_params = shift;
    my %constraints;

    foreach my $input (@inputs) {
        my %hash = (
            constraint_method   => $method,
        );
        unless( $no_params ) {
            $hash{params} = [\$format];
        }
        $constraints{$input} = \%hash;
    }
    return \%constraints;
};
