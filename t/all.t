use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
plan(tests => 17);

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import();
my $format      = '%m/%d/%Y';
my $good_date   = '02/17/2005';
my $unreal_date = '02/31/2005';
my $bad_date    = '0/312/005';
my $profile     = {
    validator_packages      => ['Data::FormValidator::Constraints::DateTime'], 
    required                => [qw(good bad unreal)],
    untaint_all_constraints => 1,
};
my $data        = {
    good   => $good_date,
    unreal => $unreal_date,
    bad    => $bad_date,
};
my $results;

# 2._5
# to_datetime
{
    $profile->{constraints} = _make_constraints('to_datetime');
    $results = Data::FormValidator->check($data, $profile);
    ok( $results->valid('good'), 'datetime expected valid');
    ok( $results->invalid('bad'), 'datetime expected invalid');
    my $date = $results->valid('good');
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

    # 6..8
    # to_mysql_datetime
    {
        $profile->{constraints} = _make_constraints('to_mysql_datetime');
        $results = Data::FormValidator->check($data, $profile);
        ok( $results->valid('good'), 'mysql_datetime expected valid');
        ok( $results->invalid('bad'), 'mysql_datetime expected invalid');
        my $date = $results->valid('good');
        is($date, '2005-02-17 00:00:00', 'mysql_datetime correct format');
    }
    
    # 9..11
    # to_mysql_date
    {
        $profile->{constraints} = _make_constraints('to_mysql_date');
        $results = Data::FormValidator->check($data, $profile);
        ok( $results->valid('good'), 'mysql_date expected valid');
        ok( $results->invalid('bad'), 'mysql_date expected invalid');
        my $date = $results->valid('good');
        is($date, '2005-02-17', 'mysql_date correct format');
    }
    
    # 12..14
    # to_mysql_timestamp
    {
        $profile->{constraints} = _make_constraints('to_mysql_timestamp');
        $results = Data::FormValidator->check($data, $profile);
        ok( $results->valid('good'), 'mysql_timestamp expected valid');
        ok( $results->invalid('bad'), 'mysql_timestamp expected invalid');
        my $date = $results->valid('good');
        is($date, '20050217000000', 'mysql_timestamp correct format');
    }
}

# test to see if we have DateTime::Format::Pg
my $HAVE_DT_FORMAT_PG = 0;
eval { require DateTime::Format::Pg };
$HAVE_DT_FORMAT_PG = 1 if( !$@ );

SKIP: {
    skip('DateTime::Format::Pg not installed', 3)
        unless $HAVE_DT_FORMAT_PG;
    # 15..17
    # to_pg_datetime
    {
        $profile->{constraints} = _make_constraints('to_pg_datetime');
        $results = Data::FormValidator->check($data, $profile);
        ok( $results->valid('good'), 'pg_datetime expected valid');
        ok( $results->invalid('bad'), 'pg_datetime expected invalid');
        my $date = $results->valid('good');
        is($date, '2005-02-17 00:00:00.000000000+0000', 'pg_datetime correct format');
    }
}


sub _make_constraints {
    my $method = shift;
    my $constraints = {
        good    => {
            constraint_method => $method,
            params            => [\$format],
        },
        bad     => {
            constraint_method => $method,
            params            => [\$format],
        },
        unreal  => {
            constraint_method => $method,
            params            => [\$format],
        },
    };
    return $constraints;
};
