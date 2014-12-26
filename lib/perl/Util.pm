package Util;

#use Mail::Sendmail;

sub print_hash_handle_hash_
{
    my($handle, $key, $value, $level) = @_;
    print $handle " " x ($level*3);
    print $handle "$key = ";
    print_hash($value, undef, $level, $handle);
}

sub print_hash_handle_array_
{
    my($handle, $key, $value, $level) = @_;

    print $handle " " x ($level*3);
    print $handle "$key = \n" ;
    print $handle " " x (($level+1)*3);
    print $handle "[\n";
    for(my $i=0; $i<=$#$value; $i++) {
        print $handle " " x (($level+1)*3);
        print $handle $value->[$i] . "\n";
    }
    print $handle " " x (($level+1)*3);
    print $handle "]\n";
}

sub print_hash
{
    my ($the_hash, $hash_name, $level, $handle) = @_;
    if(! defined $level) {
        $level = 0;
    }
    if(!defined $handle) {
        $handle = STDOUT;
    }
    ++$level;
    print $handle "\n";
    if(defined $hash_name) {
        print $handle $hash_name . " = \n";
    }
    print $handle " " x ($level*3);
    print $handle "(\n";
    if(defined $the_hash) {
        foreach $key (keys %$the_hash) {
            $value = $the_hash->{$key};

            if(!defined $value) {
                print $handle " " x ($level*3);
                $value = "[[undef]]";
                print $handle "$key = $value\n";
            }
            elsif (!ref $value || ref $value eq 'CODE') {
                print $handle " " x ($level*3);
                print $handle "$key = $value\n";
            }
            elsif(ref $value eq 'HASH') {
                print_hash_handle_hash_($handle, $key, $value, $level);
            }
            elsif(ref $value eq 'ARRAY') {
                print_hash_handle_array_($handle, $key, $value, $level);
            }
            elsif(ref $value eq 'CODE') {
                print_hash_handle_array_($handle, $key, $value, $level);
            }
            elsif($value->isa('HASH')) {
                print_hash_handle_hash_($handle, $key, $value, $level);
            }
            elsif($value->isa('ARRAY')) {
                print_hash_handle_array_($handle, $key, $value, $level);
            }
            else {
                print $handle " " x ($level*3);
                print $handle "$key = $value\n";
            }
        }
    }
    print $handle " " x ($level*3);
    print $handle ")\n";

}
# ===================================
sub hash_to_string_handle_hash_
{
    my($handle, $key, $value, $level) = @_;
    $handle .= " " x ($level*3);
    $handle .= "$key = ";

    $handle = hash_to_string($value, undef, $level, $handle);

    return $handle;
}

sub hash_to_string_handle_array_
{
    my($handle, $key, $value, $level) = @_;

    $handle .= " " x ($level*3);
    $handle .= "<li>$key = \n" ;
    $handle .= " " x (($level+1)*3);
    $handle .= "<ul><br>";
    for(my $i=0; $i<=$#$value; $i++) {
        $handle .= " " x (($level+1)*3);
        my($v) = $value->[$i];
        if(ref $v eq 'HASH') {
            $handle = hash_to_string($v, undef, $level, $handle);
        }
        else {
            $handle .= "<li>" . $v . "\n";
        }
    }
    $handle .= " " x (($level+1)*3);
    $handle .= "</ul><br>";

    return $handle;
}

sub hash_to_string
{
    my ($the_hash, $hash_name, $level, $handle) = @_;
    if(! defined $level) {
        $level = 0;
    }
    if(!defined $handle) {
        $handle = "";
    }
    ++$level;
    $handle .= "<br>";
    if(defined $hash_name) {
        $handle .= $hash_name . " = <br>";
    }
    $handle .= " " x ($level*3);
    $handle .= "<br><ul>";

    if(defined $the_hash) {
        foreach $key (sort(keys %$the_hash)) {
            $value = $the_hash->{$key};

            if(!defined $value) {
                $handle .= " " x ($level*3);
                $value = "[[undef]]";
                $handle .= "<li>$key = $value\n";
            }
            elsif (!ref $value || ref $value eq 'CODE') {
                $handle .= " " x ($level*3);
                $handle .= "<li>$key = $value\n";
            }
            elsif(ref $value eq 'HASH') {
                $handle = 
                    hash_to_string_handle_hash_($handle, $key, $value, $level);
            }
            elsif(ref $value eq 'ARRAY') {
                $handle = 
                    hash_to_string_handle_array_($handle, $key, $value, $level);
            }
            elsif(ref $value eq 'CODE') {
                $handle = 
                    hash_to_string_handle_array_($handle, $key, $value, $level);
            }
            elsif($value->isa('HASH')) {
                $handle = 
                    hash_to_string_handle_hash_($handle, $key, $value, $level);
            }
            elsif($value->isa('ARRAY')) {
                $handle = 
                    hash_to_string_handle_array_($handle, $key, $value, $level);
            }
            else {
                $handle .= " " x ($level*3);
                $handle .= "<li>$key = $value\n";
            }
        }
    }
    $handle .= " " x ($level*3);
    $handle .= "<br></ul>";

    return $handle;
}

# ===================================

sub read_file_into_string
{
    my($file_name, $quiet) = @_;
    my($contents)  = undef;
    my($orig_sep)  = $/;

    $/ = undef;
    if(defined $file_name) {
        open(CONFIG, "<$file_name") || 
            warn "Could not open file: $file_name. $!\n" unless $quiet;
        $contents = <CONFIG>;
        close(CONFIG);
    }
    $/ = $orig_sep;
    return $contents;
}

sub eval
{
    my($config_file__) = @_;
    my($errors__)      = undef;

    if(!defined $config_file__) {
        $errors__ = "'undef' passed in as file name";
        return (undef, $errors__);
    }

    my($contents__) = 
        Util::read_file_into_string($config_file__);

    no strict;
    my $eval_result__ = eval($contents__);
    use strict;
    if(!defined $eval_result__) {
        $errors__ = $@;
    }
    return ($eval_result__, $errors__);
}

sub app_log
{
    my($program_id, $sub_system_code, 
       $message_number, $level, $message) = @_;
    my($cmd) = "logMessage.ksh $program_id $sub_system_code $message_number ";
    $cmd    .= "$level \"$message\" 2>&1 >/dev/null";
    system($cmd);
}

sub mail
{
    return mail_smtp(@_);
}

#sub mail_smtp
#{
    #my($config) = shift;
    #my($success) = 1;
    #sendmail(%$config) or {$success = 0};
    #my($errors) = undef;
    #my($log) = $Mail::Sendmail::log;
    #if(!$success) {
        #$errors = $Mail::Sendmail::error;
    #}    
    #return ($success, $errors, $log);
#}

sub get_address
{
    my($email) = shift;
    $email =~ s/(.*?\<)(.*?)(\>)/$2/g;
    return $email;
}

sub get_cak416_list
{
    my($config) = shift;
    my(@to) = split(',', $config->{To});
    my(@bcc) = split(',',$config->{Bcc});
    my(@result) = ();
    foreach(@to, @bcc) {
        push(@result, get_address($_));
    }
    return(@result);
}

# usage: cak416 filename(s)
#        cak416 -s path_nm sfx dest_id [-q hhmm(_[cent]mmdd)]
#        cak416 -d path_nm sfx dest_list_id [-q hhmm(_[cent]mmdd)]
#        cak416 -v
#        cak416 -x file_nm
#        cak416 -t trigger_file_suffix
#        cak416 commfile -e address [ -replyto | -time_limit | -subject subj | -attachment ]
#        cak416 -e address -a attachment [ -replyto | -time_limit | -subject subj | -attachment ]
sub mail_cak416
{
    my($config) = shift;
    my($addresses) = $config->{To};
    my($now) = time();
    my($attachment) = "/tmp/$now.mail_cak416.tmp";
    my($subject) = $config->{Subject};
    my($from) = get_address($config->{From});

    open(ATTACHMENT, ">$attachment") || 
        warn "Could not open: $attachment.  " .
        "The message won't have a body.";
    print ATTACHMENT "$config->{Message}\n\n";
    close(ATTACHMENT);
    my(@list) = get_cak416_list($config);
    foreach my $address(@list) {
        my($cmd) = "cak416 -e \"$address\" -a $attachment " . 
            "-subject \"$subject\" -replyto \"$from\"";
        # print("$cmd\n");
        system($cmd);
    }
    unlink($attachment);
}

sub process_config
{
    my($args_ref) = @_;

    my($result, $errors) =
        Util::eval($args_ref->{"config_file"});
    if(defined $result) {
        $args_ref->{"config"} = $result;
    }
    else {
        print "Could not load [";
        print $args_ref->{"config_file"} . "].\nERRORS:\n$errors\n";
        $args_ref->{"config"} = {};
    }
    return($result, $errors);
}

1;
__END__
