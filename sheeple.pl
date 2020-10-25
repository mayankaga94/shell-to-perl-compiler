#!/usr/bin/perl -w

sub Echo {
    # split echo line on space
    my @line = split(' ',$_[0],2);
    $output .= "print \"";
    $new_line = "";
    $start = 1;
    # check for -n option
    if ($line[1] =~ /^(-n)/){
            $new_line = "yes";
            $line[1] =~ s/^(-n )//g;
    }
    # check for opening and closing quotes
    if ($line[$start] =~ /^['"]/){
        $line[$start] = substr($line[$start],1);
    }
    if ($line[$start] =~ /['"]$/){
        $line[$start] = substr($line[$start],0,-1);
    }
    # Escpape double quotes
    if ($line[$start] =~ /"/){
            $line[$start] =~ s/"/\\"/g; 
    }
    $output .= $line[$start];
    if ($new_line){
        # remove \n if -n option is provided
        $output .= "\";\n";
    }
    else {
        $output .= "\\n\";\n";
    }
}

sub Assign {
    my @line = @_;
    $line[1] =~ tr/\n//;
    $output .= "\$".  $line[0] . " = ";
    if ($line[1] =~ /^\$/){
        $output .= "$line[1]";
    }
    else {
        $output .= "'$line[1]'";
    }
}

sub For {
    # Only for --> (for x in ...)
    my @line = split(' ',$_[0]);
    $output .= "foreach " . "\$" . $line[1] . " (";
    if ($line[3] =~ /[*?]/){
        $output .= "glob(\"$line[3]\"))";
    }
    else {
        for(my $i = 3; $i <= @line-1; $i++){
            $output .= "'$line[$i]'";
            # print("$line[$i]\n");
            if ($i == @line-1){
                $output .= ")"; 
            }
            else {
                $output .= ",";
            }
        }
    }
    
}

sub Test {
    # test or []
    my @line = split(" ",$_[0]);
    $start = 2;
    if ($line[2] =~ /^-/){
        $output .= "$line[2] '$line[3]'";
        return;
    }
    # if L.H.S is a variable
    if ($line[$start] =~ /^\$/ || $line[$start] =~ /^@/){
        $output .= "$line[$start] ";
    }
    else {
        $output .= "'$line[$start]' ";
    }
    # Assignment (eq,<,>,<=,>= ... etc)
    if ($line[$start+1] eq "="){
        $output .= "eq ";
    }
    elsif($line[$start+1] eq "-le"){
        $output .= "<= ";
    }
    elsif($line[$start+1] eq "-lt"){
        $output .= "< ";
    }
    elsif($line[$start+1] eq "-ge"){
        $output .= ">= ";
    }
    elsif($line[$start+1] eq "-gt"){
        $output .= "> ";
    }
    elsif($line[$start+1] eq "-eq"){
        $output .= "== ";
    }
    elsif($line[$start+1] eq "-ne"){
        $output .= "!= ";
    }
    # If R.H.S is a variable
    if ($line[$start+2] =~ /^\$/){
        $output .= "$line[$start+2]";
    }
    else {
        $output .= "'$line[$start+2]'";
    }
}

$output = "#!/usr/bin/perl -w\n";
while($_ = <>){
    chomp($_);
    $_ =~ s/^\s+//;
    # check if any special variables(numbers)
    if ($_ =~ /\$@/ || $_ =~ /\$\*/ || $_ =~ /\$#/){
        $_ =~ s/"\$@"/\@ARGV/;
        $_ =~ s/\$@/\@ARGV/;
        $_ =~ s/\$#/\@ARGV/;
        $_ =~ s/"\$\*"/\@ARGV/;
        $_ =~ s/\$\*/\@ARGV/;
    }
    if ($_ =~ /\$[1-9]+/){
        # Check if special character(number) is being assigned
        if($_ =~ /=\$[1-9]+/){
            my @line = split('=',$_);
            # print($word);
            my($dollar,$arg) = split('',$line[1],2);
            # get index $ARGV[index]
            my $arg_index = $arg - 1;
            # String to replace
            my $perl_arg = "\$ARGV[$arg_index]";
            # Replace $n with $ARGV[n-1]
            $_ =~ s/\Q$line[1]/$perl_arg/g; 
        }
        # If $n occurs anywhere other than assignment
        my @line = split(' ',$_);
        foreach $word (@line){
            # if word matches $1 ..... $n
            if($word =~ /^[\$][1-9]+/){
                # print($word);
                my($dollar,$arg) = split('',$word,2);
                # get index $ARGV[index]
                my $arg_index = $arg - 1;
                # String to replace
                my $perl_arg = "\$ARGV[$arg_index]";
                # Replace $n with $ARGV[n-1]
                $_ =~ s/\Q$word/$perl_arg/g;
            }
        }
    }
    if ($_ =~ /`/ || $_ =~ /\)\)/){
        $_ =~ s/`//g;
        $_ =~ s/\)\)//g;
    }
    if ($_ =~ /expr / || $_ =~ /\$\(\(/){
        $_ =~ s/expr //g;
        $_ =~ s/\(\(//g;
    }
    if ($_ =~ / #/){
        $_ =~ s/ #.*//g;
    }
    if ($_ eq "" || $_ =~ /^#!/){
        next;
    }
    elsif ($_ =~ /^(echo)/){
        Echo($_);
    }
    elsif($_ =~ /^#/ && $_ !~ /^#!/){
        # comments
        $output .= $_."\n";
    }
    # cd
    elsif($_ =~ /^(cd)/){
        # assuming no spaces in directory
        my @line = split(' ',$_);
        $output .= "chdir '" . $line[1] . "';\n";
    }
    elsif($_ =~ /^(read)/){
        my @line = split(' ',$_);
        $output .= "\$$line[1] = <STDIN>;\nchomp \$$line[1];\n";
    }
    elsif($_ =~ /^(exit)/){
        $output .= "$_;\n";
    }
    # for loop
    elsif($_ =~ /^(for)/){
        For($_);
    }
    # open for loop
    elsif($_ =~ /^(do)$/){
        $output .= "{\n";
    }
    #close for loop
    elsif($_ =~ /^(done)$/){
        $output .= "}\n";
    }
    # if
    elsif($_ =~ /^(if)/){
        $output .= "if (";
        Test($_);
        $output .= ")";
    }
    elsif($_ =~ /^(then)/){
        $output .= "{\n";
    }
    elsif($_ =~ /^(elif)/){
        $output .= "} elsif (";
        Test($_);
        $output .= ")";
    }
    elsif($_ =~ /^(else)/){
        $output .= "} else {\n";
    }
    elsif($_ =~ /^(fi)$/){
        $output .= "}\n";
    }
    # While loop
    elsif($_ =~ /^(while)/){
        $output .= "while (";
        my @line = split(" ",$_);
        if ($line[1] eq "test" || $line[1] eq "["){
            Test($_);
            $output .= ")";
        }
        elsif($line[1] eq "true"){
            $output .= "1)"
        }
        elsif($line[1] eq "false"){

        }
    }
    # Variable assignment
    elsif($_ =~ /=/){
        my @line = split('=',$_);
        if ($line[1] =~ /^(`expr)/){

        }
        Assign(@line);
        $output .= ";\n";
    }
    else {
        # use system
        $output .= "system \"" . $_ . "\";\n";
    }
}
print($output);

