use Test::More;
use strict;
use Data::FormValidator;
use DateTime;
plan(tests => 13);

# 1
use_ok('Data::FormValidator::Constraints::DateTime');
Data::FormValidator::Constraints::DateTime->import();
my $format = '%m/%d/%Y';
my $good_date = '02/17/2005';
my $bad_date = '02/31/2005';

my $profile = {
    validator_packages      => ['Data::FormValidator::Constraints::DateTime'], 
    required                => [qw(
        datetime_good           datetime_bad
        mysql_datetime_good     mysql_datetime_bad
        mysql_date_good         mysql_date_bad
        mysql_timestamp_good    mysql_timestamp_bad
        pg_datetime_good        pg_datetime_bad
    )],
    constraints             => {
        datetime_good           => {
            constraint_method       => 'to_datetime',
            params                  => [\$format],
        },
        datetime_bad            => {
            constraint_method       => 'to_datetime',
            params                  => [\$format],
        },
        mysql_datetime_good     => {
            constraint_method       => 'to_mysql_datetime',
            params                  => [\$format],
        },
        mysql_datetime_bad      => {
            constraint_method       => 'to_mysql_datetime',
            params                  => [\$format],
        },
        mysql_date_good         => {
            constraint_method       => 'to_mysql_date',
            params                  => [\$format],
        },
        mysql_date_bad          => {
            constraint_method       => 'to_mysql_date',
            params                  => [\$format],
        },
        mysql_timestamp_good    => {
            constraint_method       => 'to_mysql_timestamp',
            params                  => [\$format],
        },
        mysql_timestamp_bad     => {
            constraint_method       => 'to_mysql_timestamp',
            params                  => [\$format],
        },
        pg_datetime_good        => {
            constraint_method       => 'to_pg_datetime',
            params                  => [\$format],
        },
        pg_datetime_bad         => {
            constraint_method       => 'to_pg_datetime',
            params                  => [\$format],
        },
    },
    untaint_all_constraints => 1,
};

my $data = {
    datetime_good           => $good_date,
    datetime_bad            => $bad_date,
    mysql_datetime_good     => $good_date,
    mysql_datetime_bad      => $bad_date,
    mysql_date_good         => $good_date,
    mysql_date_bad          => $bad_date,
    mysql_timestamp_good    => $good_date,
    mysql_timestamp_bad     => $bad_date,
    pg_datetime_good        => $good_date,
    pg_datetime_bad         => $bad_date,
};

my $results = Data::FormValidator->check($data, $profile);

# 2..5
# to_datetime
ok( $results->valid('datetime_good'), 'datetime expected valid');
ok( $results->invalid('datetime_bad'), 'datetime expected invalid');
my $dt = $results->valid('datetime_good');
isa_ok( $dt, 'DateTime');
is( "$dt", $good_date, 'DateTime stringifies correctly');

# 6..7
# to_mysql_datetime
ok( $results->valid('mysql_datetime_good'), 'mysql_datetime expected valid');
ok( $results->invalid('mysql_datetime_bad'), 'mysql_datetime expected invalid');

# 8..9
# to_mysql_date
ok( $results->valid('mysql_date_good'), 'mysql_date expected valid');
ok( $results->invalid('mysql_date_bad'), 'mysql_date expected invalid');

# 10..11
# to_mysql_timestamp
ok( $results->valid('mysql_timestamp_good'), 'mysql_timestamp expected valid');
ok( $results->invalid('mysql_timestamp_bad'), 'mysql_timestamp expected invalid');

# 12..13
# to_pg_datetime
ok( $results->valid('pg_datetime_good'), 'pg_datetime expected valid');
ok( $results->invalid('pg_datetime_bad'), 'pg_datetime expected invalid');


