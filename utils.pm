package debug::utils;

use Devel::StackTrace;
use Data::Dumper;
use Time::HiRes qw(time gettimeofday);

my $output_file = "/var/log/debug.log";
my $realtime_debug_file = "debug/realtime_debug";
our $DEBUG = 1;
my $timer = time();

sub new	{
	my $class = shift;
	my $self = {
      timer => time(),
    };

	bless $self, $class;

    return $self;
}

sub SetDebug {
  my $self = shift;
  my $debug_level = shift;

  $DEBUG = ($debug_level == undef) ? 1 : $debug_level;
}

sub ClearDebug {
  my $self = shift;
  $DEBUG = 0;
}

sub IsDebugLevel {
  my $self = shift;
  my $debug_level = shift;

  if (-e $realtime_debug_file) {
    open(INFILE, $realtime_debug_file);
    my @lines = <INFILE>;
    close(INFILE);
    if ($#lines > -1) {
      chomp $lines[0];
      $DEBUG = int($lines[0]);
    }
  }
  if ($debug_level <= $DEBUG) {
    return 1;
  }
  else {
    return 0;
  }
}

sub StartTimer {
  my $self = shift;

  if (exists($self->{timer})) {
    $self->{timer} = time();
  }
  else {
    $timer = time();
  }
}

sub RestartTimer {
  my $self = shift;

  if (exists($self->{timer})) {
    my $total_time = time() - $self->{timer};
    $self->{timer} = time();
    return sprintf("%f", $total_time);
  }
  else {
    my $total_time = time() - $timer;
    $timer = time();
    return sprintf("%f", $total_time);
  }
}

sub GetTimer {
  my $self = shift;

  if (exists($self->{timer})) {
    my $total_time = time() - $self->{timer};
    return sprintf("%f", $total_time);
  }
  else {
    my $total_time = time() - $timer;
    return sprintf("%f", $total_time);
  }
}

sub GetCurrentTime {
  my $self = shift;

  my $time = time;
  my $seconds = int($time);
  my $milliseconds = int(($time - $seconds)*1000);
  my ($sec, $mi, $hr, $day, $mo, $yr, $wday, $yday, $isdst) = localtime($seconds);
  my $now = sprintf("%04d/%02d/%02d:%02d:%02d:%02d.%03d", $yr + 1900, $mo + 1, $day, $hr, $mi, $sec, $milliseconds);
  return $now;
}

sub Traceback {
  my $self = shift;
  my @args = @_;

  my $debug_value = $DEBUG;
  my @debug_values = grep (/^--debug=.+$/, @args);
  if ($#debug_values >= 0) {
    $debug_value = (split /=/, $debug_values[0])[1];
    @args = grep (! /^--debug=.+$/, @args);
  }

  return if ! $self->IsDebugLevel($debug_value);

  my $print_log = 1;
  my $print_date = 1;
  if (grep (/^--nodate$/, @args)) {
    $print_date = 0;
    @args = grep (! /^--nodate$/, @args);
  }
  if (grep (/^--nolog$/, @args)) {
    $print_log = 0;
    @args = grep (! /^--nolog$/, @args);
    open(OUTPUT, ">>&STDOUT");
  }
  elsif (grep (/^--output_log=/, @args)) {
    open(OUTPUT, ">>".  (split /=/, (grep (/^--output_log=.+$/, @args))[0])[1]);
    @args = grep (! /^--output_log=.+$/, @args);
  }
  else {
    open(OUTPUT, ">>$output_file");
  }
  my $first = 1;
  my $trace = Devel::StackTrace->new;
  my @frames = $trace->frames();
  my @messages = ();
  my $message = '##### ';
  if ($print_date) {
    $message .= ($self->GetCurrentTime()." ");
  }
  $message .= "Trace begun\n";
  push @messages, $message;
  for (my $i = 0; $i <= $#frames; $i++) {
    $message = '##### ';
    if ($print_date) {
      $message .= ($self->GetCurrentTime()." ");
    }
    my $line = $frames[$i]->as_string($first);
    $line =~ s/^.+called at/called at/;
    $line =~ s/ line /:/;
    $line =~ s/Trace begun at //;
    $message .= "$line".($i < $#frames ? ":".$frames[$i+1]->subroutine : '')."\n";
    push @messages, $message;
    $first = 0;
  }
  $message = '##### ';
  if ($print_date) {
    $message .= ($self->GetCurrentTime()." ");
  }
  $message .= "Trace complete\n";
  push @messages, $message;

  delete $messages[1];
 
  for (my $i = 0; $i <= $#messages; $i++) {
      print OUTPUT $messages[$i];
  }
  if ($#args >= 0) {
    my $line = $messages[2];
    $line =~ s/\n//;
    $line =~ s/called at //;
    for (my $i = 0; $i <= $#args; $i++) {
      if ((ref($args[$i]) eq 'ARRAY') || (ref($args[$i]) eq 'HASH')) {
        my @results = split "\n", Dumper($args[$i]);
        my $results = Dumper($args[$i]);
        print OUTPUT $line, ": ", $results;
      }
      elsif (ref($args[$i]) ne "") {
        my $object = Data::Dumper->new([$args[$i]]);
        my $results = $object->Dump;
        print OUTPUT $line, ": ", $results;
      }
      else {
        chomp($args[$i]);
        print OUTPUT $line, ": ", $args[$i], "\n";
      }
    }
  }
  close(OUTPUT);
}

sub Log {
  my $self = shift;
  my @args = @_;

  my $debug_value = $DEBUG;
  my @debug_values = grep (/^--debug=.+$/, @args);
  if ($#debug_values >= 0) {
    $debug_value = (split /=/, $debug_values[0])[1];
    @args = grep (! /^--debug=.+$/, @args);
  }

  return if ! $self->IsDebugLevel($debug_value);

  my $print_date = 1;
  my $print_cr = 1;
  my $print_log = 1;
  my $print_line_no = 1;
  if (grep (/^--nodate$/, @args)) {
    $print_date = 0;
    @args = grep (! /^--nodate$/, @args);
  }
  if (grep (/^--nocr$/, @args)) {
    $print_cr = 0;
    @args = grep (! /^--nocr$/, @args);
  }
  my $trace_start;
  if (grep (/^--nolog$/, @args)) {
    $print_log = 0;
    @args = grep (! /^--nolog$/, @args);
    open(OUTPUT, ">>&STDOUT");
    $trace_start = 2;
  }
  elsif (grep (/^--output_log=/, @args)) {
    open(OUTPUT, ">>".  (split /=/, (grep (/^--output_log=.+$/, @args))[0])[1]);
    @args = grep (! /^--output_log=.+$/, @args);
    $trace_start = 1;
  }
  else {
    open(OUTPUT, ">>$output_file");
    $trace_start = 1;
  }
  my ($trace, $f1, $f2);
  if (grep (/^--no_line_no$/, @args)) {
    $print_line_no = 0;
    @args = grep (! /^--no_line_no$/, @args);
  }
  else {
    $trace = Devel::StackTrace->new;
    $f1 = ($trace->frames())[$trace_start];
    $f2 = ($trace->frames())[$trace_start+1];
  }
  if ($#args < 0) {
    my $message = "----->";
    if ($print_date) {
      $message .= ($self->GetCurrentTime()." ");
    }
    if ($print_line_no) {
      $message .= ($f1->filename.":".$f1->line.":".(defined($f2) ? $f2->subroutine.":" : ""));
    }
    $message .= "\n";
    print OUTPUT $message;
  }
  else {
    my $message;
    for (my $i = 0; $i <= $#args; $i++) {
      if ($i == 0 || $print_cr) {
        $message = "----->";
        if ($print_date) {
          $message .= ($self->GetCurrentTime()." ");
        }
        if ($print_line_no) {
          $message .= ($f1->filename.":".$f1->line.":".(defined($f2) ? $f2->subroutine.":" : "")." ");
        }
      }
      if ((ref($args[$i]) eq 'ARRAY') || (ref($args[$i]) eq 'HASH')) {
        my $results = Dumper($args[$i]);
        $message .= $results;
      }
      elsif (ref($args[$i]) ne "") {
        my $object = Data::Dumper->new([$args[$i]], [ref($args[$i])]);
        $message .= $object->Dump;
      }
      else {
        chomp($args[$i]);
        if ($print_cr) {
	  $message .= "$args[$i]\n";
        }
        else {
          if ($i != 0) {
	    $message .= ", ";
          }
	  $message .= $args[$i];
        }
      }
      if ($print_cr) {
        print OUTPUT $message;
      }
    }
    if (!$print_cr) {
      print OUTPUT "$message\n";
    }
  }
  close(OUTPUT);
}

sub Print {
  my $self = shift;
  $self->Log(@_, "--nolog");
}

1;
