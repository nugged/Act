#!perl -w

use strict;
use List::Util qw(sum);
use Test::More;

my @tests = (
{ profile => {
      required => [ qw(r1 r2) ],
      optional => [ qw(r3) ],
      desc     => 'required',
  },
  inputs => [
    { input  => { r1 => 1, r2 => 2 },
      fields => { r1 => 1, r2 => 2 },
      valid  => 1,
      desc   => 'all there',
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3 },
      fields => { r1 => 1, r2 => 2, r3 => 3 },
      valid  => 1,
      desc   => '+ optional',
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3, r4 => 4 },
      fields => { r1 => 1, r2 => 2, r3 => 3 },
      valid  => 1,
      desc   => '+ optional + unknown',
    },
    { input  => { r1 => 'foo  ', r2 => '  bar', r3 => ' baz '},
      fields => { r1 => 'foo',   r2 => 'bar',   r3 => 'baz' },
      valid  => 1,
      desc   => '+ unknown',
    },
    { input  => { r1 => 1, r2 => 2, r3 => '' },
      fields => { r1 => 1, r2 => 2, r3 => '' },
      valid  => 1,
      desc   => '+ empty optional',
    },
    { input  => { r1 => 1, r2 => 2, r3 => undef },
      fields => { r1 => 1, r2 => 2 },
      valid  => 1,
      desc   => '+ undef optional',
    },
    { input  => { r1 => 1, r3 => 3 },
      fields => { r1 => 1, r3 => 3 },
      valid  => '',
      invalid => { r2 => 'required' },
      desc   => 'partly missing',
    },
    { input  => { r1 => 1, r2 => '', r3 => 3 },
      fields => { r1 => 1, r2 => '', r3 => 3 },
      valid  => '',
      invalid => { r2 => 'required' },
      desc   => 'empty required',
    },
    { input  => { r1 => 1, r2 => undef, r3 => 3 },
      fields => { r1 => 1, r3 => 3 },
      valid  => '',
      invalid => { r2 => 'required' },
      desc   => 'undef required',
    },
  ],
},
{ profile => {
      dependencies => { r1 => [ qw(r2 r3) ] },
      desc => 'dependencies',
  },
  inputs => [
    { input  => {  },
      fields => {  },
      valid  => 1,
      desc   => 'none',
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3 },
      fields => { r1 => 1, r2 => 2, r3 => 3 },
      valid  => 1,
      desc   => 'all there',
    },
    { input  => { r1 => 1 },
      fields => { r1 => 1 },
      valid  => '',
      invalid => { r2 => 'required', r3 => 'required' },
      desc   => 'missing',
    },
    { input  => { r1 => 1, r2 => 2 },
      fields => { r1 => 1, r2 => 2 },
      invalid => { r3 => 'required' },
      valid  => '',
      desc   => 'partly missing',
    },
  ],
},
{ profile => {
      dependencies => { r1 => [ qw(r2) ],
                        r3 => [ qw(r4) ],
                      },
      desc => 'multiple dependencies',
  },
  inputs => [
    { input  => { r1 => 1 },
      fields => { r1 => 1 },
      valid  => '',
      invalid => { r2 => 'required' },
      desc   => 'partial input, missing',
    },
    { input  => { r1 => 1, r2 => 2 },
      fields => { r1 => 1, r2 => 2 },
      valid  => 1,
      desc   => 'partial input, all there',
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3 },
      fields => { r1 => 1, r2 => 2, r3 => 3 },
      valid  => '',
      invalid => { r4 => 'required' },
      desc   => 'partly missing',
    },
    { input  => { r1 => 1, r3 => 3 },
      fields => { r1 => 1, r3 => 3 },
      valid  => '',
      invalid => { r2 => 'required', r4 => 'required' },
      desc   => 'all missing',
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3, r4 => 4 },
      fields => { r1 => 1, r2 => 2, r3 => 3, r4 => 4 },
      valid  => 1,
      desc   => 'all there',
    },
  ],
},
{ profile => {
      required => 'r1',
      constraints => { r1 => 'email' },
      desc => 'email',
  },
  inputs => [
    { input  => { r1 => 'foo@example.com' },
      fields => { r1 => 'foo@example.com' },
      valid  => 1,
      desc   => 'valid',
    },
    { input  => { r1 => 'foo@example' },
      fields => { r1 => 'foo@example' },
      valid  => '',
      invalid => { r1 => 'email' },
      desc   => 'invalid',
    },
    { input  => {  },
      fields => {  },
      valid  => '',
      invalid => { r1 => 'required' },
      desc   => 'required',
    },
  ],
},
{ profile => {
      required => 'r1',
      constraints => { r1 => 'numeric' },
      desc => 'required numeric',
  },
  inputs => [
    { input  => { r1 => 42 },
      fields => { r1 => 42 },
      valid  => 1,
      desc   => 'valid',
    },
    { input  => { r1 => 0 },
      fields => { r1 => 0 },
      valid  => 1,
      desc   => 'zero',
    },
    { input  => {  },
      fields => {  },
      valid  => '',
      invalid => { r1 => 'required' },
      desc   => 'missing',
    },
    { input  => { r1 => 'abc' },
      fields => { r1 => 'abc' },
      valid  => '',
      invalid => { r1 => 'numeric' },
      desc   => 'non numeric',
    },
  ],
},
{ profile => {
      optional    => 'r1',
      constraints => { r1 => 'numeric' },
      desc => 'optional numeric',
  },
  inputs => [
    { input  => { r1 => 42 },
      fields => { r1 => 42 },
      valid  => 1,
      desc   => 'valid',
    },
    { input  => { r1 => 0 },
      fields => { r1 => 0 },
      valid  => 1,
      desc   => 'zero',
    },
    { input  => { r1 => undef },
      fields => {  },
      valid  => 1,
      desc   => 'undef',
    },
    { input  => { r1 => '' },
      fields => { r1 => '' },
      valid  => 1,
      desc   => 'empty',
    },
    { input  => { r1 => 'abc' },
      fields => { r1 => 'abc' },
      valid  => '',
      invalid => { r1 => 'numeric' },
      desc   => 'non numeric',
    },
  ],
},
{ profile => {
      optional    => 'r1',
      constraints => { r1 => sub { $_[0] =~ /^[A-Z]*$/ } },
      desc   => 'custom constraint',
  },
  inputs => [
    { input  => { r1 => 'ABC' },
      fields => { r1 => 'ABC' },
      valid  => 1,
      desc   => 'valid',
    },
    { input  => {  },
      fields => {  },
      valid  => 1,
      desc   => 'missing',
    },
    { input  => { r1 => 'abc' },
      fields => { r1 => 'abc' },
      valid  => '',
      invalid => { r1 => 'custom' },
      desc   => 'invalid',
    },
  ],
},
{ profile => {
      required    => 'r1',
      constraints => { r1 => 'url' },
      desc   => 'url',
  },
  inputs => [
    { input  => { r1 => 42 },
      fields => { r1 => 42 },
      valid  => '',
      invalid => { r1 => 'url' },
      desc   => 'invalid',
    },
    { input  => { r1 => 'http://abc' },
      fields => { r1 => 'http://abc' },
      valid  => 1,
      desc   => 'valid',
    },
  ],
},
{ profile => {
      required    => [ 'r1', 'r2' ],
      constraints => { r1 => 'date', r2 => 'time' },
      desc   => 'datetime',
  },
  inputs => [
    { input  => { r1 => '2004-13-32', r2 => '88:88' },
      fields => { r1 => '2004-13-32', r2 => '88:88' },
      valid  => '',
      invalid => { r1 => 'date', r2 => 'time' },
      desc   => 'invalid',
    },
    { input  => { r1 => '1975-03-07', r2 => '14:40' },
      fields => { r1 => '1975-03-07', r2 => '14:40' },
      valid  => 1,
      desc   => 'valid',
    },
  ]
},
{ profile => {
      required    => 'r1',
      optional    => 'r2',
      filters     => {
         r1 => sub { lc shift },
         r2 => sub { ucfirst lc shift },
      },
      desc  => 'filter',
  },
  inputs => [
    { input  => { r1 => 'FOO' },
      fields => { r1 => 'foo' },
      valid  => 1,
      desc   => 'valid',
    },
    { input  => { r1 => 'FOO', r2 => 'bAr' },
      fields => { r1 => 'foo', r2 => 'Bar' },
      valid  => 1,
      desc   => 'valid',
    },
  ],
},
{ profile => {
      optional    => 'r1',
      filters     => {
         r1 => sub { $_[0] || undef },
      },
      desc  => 'filter empty values',
  },
  inputs => [
    { input  => { r1 => 'foo' },
      fields => { r1 => 'foo' },
      valid  => 1,
      desc   => 'not empty',
    },
    { input  => { r1 => '' },
      fields => { },
      valid  => 1,
      desc   => 'empty',
    },
  ],
},
{ profile => {
      optional => [ qw(r1 r2) ],
      global   => [ sub { $_[0]{r1} && !$_[0]{r2}
                                    ||
                         !$_[0]{r1} &&  $_[0]{r2}
                        }
                  ],
      desc     => 'global',
  },
  inputs => [
    { input  => { r1 => 1, r2 => 0 },
      fields => { r1 => 1, r2 => 0 },
      valid  => 1,
      desc   => 'good',
    },
    { input  => { r1 => 1, r2 => 2 },
      fields => { r1 => 1, r2 => 2 },
      valid  => '',
      desc   => 'bad',
    },
  ],
},
);
plan tests => 1 + scalar(@tests) + 3 * sum map scalar(@{$_->{inputs}}), @tests;

require_ok('Act::Form');

for my $t (@tests) {
    my $f = Act::Form->new(%{$t->{profile}});
    ok($f, "$t->{profile}{desc} new");
    for my $i (@{$t->{inputs}}) {
        my $desc = "$t->{profile}{desc} $i->{desc}";
        my $res = $f->validate($i->{input});
        is($res, $i->{valid}, "$desc - validation");
        is_deeply($f->fields, $i->{fields}, "$desc - fields");
        if ($i->{invalid}) {
            is_deeply($f->invalid, $i->{invalid}, "$desc - invalid");
        }
        else {
            ok(!defined($i->{invalid}), "$desc - invalid");
        }
    }
}

__END__
