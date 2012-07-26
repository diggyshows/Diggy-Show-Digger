#!/usr/bin/perl

use strict;
use LWP::Simple;
use JSON::XS;
use DBI;


########  CHANGE THIS PATH TO POINT TO THE DIRECTORY OF THE DIGGY SCRIP ############################################################################################

# example '/home/usr/diggy/' - YOU MUST INCLUDE THE LAST FORWARD SLASH!!!!!
my $diggy_path = '';

########  DON'T CHANGE ANYTHING BELOW THIS LINE ####################################################################################################################

my $os = $^O;
my $clear_command;
         if($os eq 'MSWin32'){$clear_command = "cls"}
         else {$clear_command = "clear"} # This should cover MAC too.
         
my %config = read_config();

if($ARGV[0] eq "getshows") {
         my $shows = shows_for_download();
            foreach my $i(@$shows){
                my $results = &get_myshow(@$i);
                print "Results for \"@$i[1] @$i[2]\" is: \n\t" . $results . "\n";
            }

            exit;                }


##################################################################################################################################################################
###############################################################    Diggy below here    ###########################################################################
##################################################################################################################################################################

my $setup = &check_config;
if($setup =="0"){
         system($clear_command);
         print "You haven't configured Diggy yet !!!!\nPlease spend some time answering the following questions:\n\n";
         run_config();

}


START:
system($clear_command);
print "####################################################\n";
print "########## Welcome to the Diggy Show Digger ########\n";
print "####################################################\n";
print "\nPlease select your option from the list below.\n
1. Add new shows to your Watcher database.\n
2. View\\Remove shows from your Watcher database.\n
3. Build the Seasons database.\n
4. Configure Shows and their Seasons.\n
5. Configure SabNZBD and NZBMatrix details.\n
6. Quit\n

Choice: ";
chomp (my $choice = <STDIN>);
if($choice == "6" || $choice eq "q" || $choice eq "Q"){print "Bye!.......\n";sleep(1);exit}

unless($choice =~ m/^[0-9]$/){print "You must enter a number\n";sleep(1);goto START;}

if($choice =="1"){system($clear_command);
                  ENTER_SHOW:
                  print "Enter show name to add. Case is not important but spacing is (type \"\\q\" to quit): ";
                  chomp (my $show = <STDIN>);
                  if(length($show) <=0) {goto ENTER_SHOW}
                  if($show eq '\q'){goto START}
                  add_shows_to_watcher($show);
                  ANOTHER:
                  print "Add another (y/n)?: ";
                  chomp (my $another = <STDIN>);
                  $another = uc($another);
                  print "$another\n";
                    unless($another eq "Y" || $another eq "N") {goto ANOTHER}
                    if($another eq "Y") {goto ENTER_SHOW}
                    else{goto START}
                  }

if($choice =="2"){SELECTION:
                  system($clear_command);
                  my $shows = get_watcher_shows();
                  
                  if(scalar @$shows =="0"){print "There are no shows in your database. Please add some.....\n\n";
                                          sleep(2);
                                          goto START;
                                          }
                  
                    print "These are the shows in your database.\n\nSelect a number to delete or \"q\" to quit.\n\n";
                    printf("%-4s %-35s\n", "No.","Showname");
                     print "-------------------------------------------\n";
                    if(@$shows){
                    foreach my $i(@$shows){
                         {print "@$i[0].  @$i[1]\n";
                          }

                         
                    }
                    } 
                  
                  print "\nSelection: ";
                  chomp (my $delete = <STDIN>);
                  if($delete eq 'q') {goto START}
                  if($delete =~ m/\d/) {
                    print "Are you sure you want to remove this show from your database? [y/n]  ";
                    chomp (my $select = <STDIN>);
                    $select = uc($select);
                    if($select eq "Y" || $select eq "YES") {
                        my $showname = delete_show($delete);
                        print "Removed all traces of \"$showname\" from your database\n";
                        sleep(2);
                        goto SELECTION;
                    }
                    if($select eq "N"){print "\nDelete Canceled......\n";
                                       sleep(2);
                                       goto SELECTION}
                    
                    elsif($select ne "Y"){print "\nInvalid choice - number or \"q\" to quit.\n";
                       sleep(2);
                       goto SELECTION}
                  }
                  
                  
                  }

if($choice == "3"){system($clear_command);
                  print "(re)Building your Seasons database. This could take a few minutes.......\n";
                  my ($ins,$skipped) = build_database();
                  system($clear_command);
                  print "Results for database build:\n\n";
                  print "We added $ins records\n";
                  print "We ignored (already had) $skipped records\n";
                  print "\n\nReturning to main menu.....\n";
                  sleep(8);
                  goto START;
        }


if($choice =="4"){MANAGE:
                  system($clear_command);
print "You NEED to read the README to understand what happens here!\n\n";
        my @count;                 
        my $shows = get_watcher_shows();               
            if(scalar @$shows =="0"){
                print "There are no shows in your database. Please add some.....\n\n";
                sleep(2);
                goto START;
            }    
        print "These are the shows in your database.\n\nSelect a number to configure or \"q\" to quit\n\n";
        printf("%-4s %-55s\n", "No.","Showname");
        print "-----------------------------------------\n";
            if(@$shows){
                foreach my $i(@$shows){
                    { print "@$i[0].  @$i[1]\n";
                     push @count,@$i[0];}
                    
                    }
                print "\nSelection: ";
                chomp (my $select = <STDIN>);
                if($select eq "q" || $select eq "Q"){goto START}
                    my $count = grep /^$select$/, @count;
                    if($count =="0") {print "Not a valid selection. Please enter the number show above for your show..\n";
                                      sleep(2);
                                      goto MANAGE}
                
                unless($select =~ m/\d/ ){print "Not a valid selection. Please enter the number show above for your show..\n";
                                      sleep(2);
                                      goto MANAGE}
                else{my $results = get_shows_and_seasons($select);
                     my %choose;
                     my @exists;
                     my $count=1;
                     system($clear_command);
                     if(scalar @$results =="0"){print "You haven't updated you database since adding this show\nPlease return to the main menu and select option 3.\n\n";
                                                sleep(4);
                                                goto START}
                     

                     foreach my $i(@$results)
                     {
                      $choose{$count} = "@$i[0]|@$i[1]|@$i[2]";
                       $count++;            
                      }
                     SHOWS:
                     system($clear_command);
                     print "Please select your Season to edit the shows you want. \"q\" to exit.\n\n";
                     printf("%-4s %-25s %-18s\n", "No.","Showname", "Episode", "Downloaded");
                     print "--------------------------------------------------------------\n";
                     foreach my $j(sort {$a <=> $b} keys %choose){
                        my ($id,$showname,$season) = split(/\|/,$choose{$j});
                            $season =~ s/s/season /;
                        printf("%-4s %-25s %-18s\n", "$j.","$showname", "$season");
                        push @exists,$j;
                                                    }
                     
                     print "\nSelect the season you want to edit: ";
                     chomp (my $season = <STDIN>);
                    if($season eq 'q' || $season eq 'Q'){goto MANAGE;}
                     my $selected = grep /$season/, @exists;
                     if($selected =="0"){print "Select a Show from you list above.\n";
                                         sleep(2);
                                         goto SHOWS}
                     unless($selected =="0"){
                        EPISODES:
                        system($clear_command);
                        my $episodes = get_seasons_to_edit($choose{$season});
                            if(scalar @$episodes =="0"){print "There are no episodes in this seasons yet\n";
                                                        sleep(3);
                                                        GOTO SHOWS
                                                        }
                        my %choose2;
                        my @exists2 =();
                        my $count = 1;
                        my %all = ();
                        my $season_s = @$episodes[0]->[4];
                        my $show_id = @$episodes[0]->[1];
                        $all{all} = "$show_id|$season_s";
                        foreach my $i(@$episodes){
                            $choose2{$count} = "@$i[0]|@$i[1]|@$i[2]|@$i[3]|@$i[4]";
                            $count++;            
                                            }

                        print "Please enter the number of episode to change. 'q' to quit.\n\n";
                        printf("%-4s %-55s %-18s %-16s\n", "No.","Showname", "Episode", "Downloaded");
                        print "------------------------------------------------------------------------------------------------------\n";

                            foreach my $j(sort {$a <=> $b} keys %choose2){
                            my ($episode,$id,$showname,$downloaded,$season) = split(/\|/,$choose2{$j});
                            $episode =~ s/e/episode /;
                            $downloaded =~ s/0/Not Downloaded/;
                            $downloaded =~ s/1/Downloaded/;
                            printf("%-4s %-55s %-18s %-16s\n", "$j.","$showname", "$episode", "$downloaded");
                            push @exists2,$j;
                    
                                                            }
                            print "\nEnter the number of the episode you have already downloaded\r\"Not Downloaeded\" means the program will try to download it on the next sync.\n";
                            print "Selection: ";
                            chomp (my $selection = <STDIN>);
                            if($selection eq 'q' || $selection eq 'Q'){goto SHOWS;}
                            if( ($selection eq "all") || ($selection eq "ALL") ) { update_all_eps_in_season($all{all}); goto EPISODES}
                            unless($selection =~ m/\d/) {print "Invalid selection.....\n";
                                                         sleep(2);
                                                         goto EPISODES;}
                            my $there = grep /^$selection$/,@exists2;
                            if($there =="0"){print "You must choose an episode in your episode list\n";
                                             sleep(2);
                                             goto EPISODES;
                                             }
                            elsif($there =="1"){update_seasons_to_download($choose2{$selection});
                                                goto EPISODES;
                                                }

                                            }
                            
                        
                    
                    }

                     }

                     
                     
         }


if($choice =="5"){print "View / Modify your configuration below\n\n";
                  system($clear_command);
                  run_config();
                  goto START;}

                  
###########################################################################################################################################################



sub update_cronpath{
   my $cron = $_[0];
   my $dbh = new_dbh();
   my $sth = $dbh->prepare("UPDATE config
                           SET cronpath = ?");
   $sth->execute($cron);
}

sub update_shows {
    my($id,$showname,$format_name) = @_;
    my $dbh = new_dbh();
    
    my $sth = $dbh->prepare("UPDATE seasons
                            SET downloaded = '1'
                            WHERE id = ?
                            AND format_name = ?");
    $sth->execute($id,$format_name);
}


sub update_all_eps_in_season{
    my ($id,$season) = split(/\|/,$_[0]);
    my $dbh = new_dbh();
    my $sth = $dbh->prepare("UPDATE seasons
                          SET downloaded = '1'
                          WHERE id = ?
                          AND season = ?");
    $sth->execute($id,$season);
}

sub update_seasons_to_download {
    my ($episode,$id,$showname,$downloaded,$season) = split(/\|/,$_[0]);
    my $dbh = new_dbh();
    my $sth = $dbh->prepare("SELECT downloaded from seasons
                            WHERE id = ?
                            AND season = ?
                            AND episode = ?");
    $sth->execute($id,$season,$episode);
    my $results = $sth->fetchrow();
    if($results=="1"){$downloaded = "0"}
    if($results=="0"){$downloaded = "1"}
    $sth = $dbh->prepare("UPDATE seasons
                            SET downloaded=?
                            WHERE id = ?
                            AND season = ?
                            AND episode = ?");
                            
    $sth->execute($downloaded,$id,$season,$episode);
    
}

sub get_seasons_to_edit {
    my $dbh = new_dbh();
    my @episodes;
    my ($id,$showname,$season) = split(/\|/,$_[0]);
    my $sth = $dbh->prepare("select distinct(episode),id,title,downloaded,season
                            from seasons where id=?
                            and season=?");
    $sth->execute($id,$season);
    while(my @rows = $sth->fetchrow_array() ){
        push @episodes,\@rows;
    }

    return \@episodes;
}

sub get_shows_and_seasons {
    my $dbh = new_dbh();
    my @results;
    my $id = $_[0];
    my $sth = $dbh->prepare("SELECT distinct(id),showname,season
                            FROM seasons
                            WHERE id = ?");
    $sth->execute($id);
    while(my @rows = $sth->fetchrow_array() ) {
        push @results,\@rows
    }
return \@results;
    
}

sub delete_show {
    my $dbh = new_dbh();
    my $showname;
    my $id = $_[0]; 
    my $sth = $dbh->prepare("SELECT showname from watcher
                            WHERE id = ?");
    $sth->execute($id);
    $showname = $sth->fetchrow();
    $sth = $dbh->prepare("DELETE from watcher
                            where id = ?");
    $sth->execute($id);
    $sth = $dbh->prepare("DELETE from seasons
                            where id = ?");
    $sth->execute($id);

$sth->finish;

return ($showname);
}

sub add_shows_to_watcher {
    my $show = $_[0];
    my $dbh = new_dbh();
    my $return = "Add show failed\n";
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM watcher
                            WHERE showname = ?");
    $sth->execute($show);
    my $row = $sth->fetchrow();
    if($row > 0) {print "\n\t!!!!! It looks like you already have the show \"$show\" in your local database. Try again.!!!!!\n\n";goto ENTER_SHOW;exit}
    $sth = $dbh->prepare("INSERT into watcher
                            (showname)
                            VALUES
                            (?)");
   eval { $sth->execute($show)};
   unless(@$){$return ="Successfully added $show\n"}
   
return $return;
    
}

sub build_database {
my $t = build_seasons();
my $season_and_episodes = build_episodes(@$t);
my ($ins,$skipped) = check_episode_exists(@$season_and_episodes);

return ($ins,$skipped);

}

sub build_seasons {
my $shows = get_watcher_shows();
my @is;
if(scalar @$shows =="0"){print "\n!!! There are no shows in your database. Please add some.......\n";
                         sleep (3);
                         goto START;
                         next;}
if(@$shows) {print "\nBuilding Database for these shows:\n"}
    foreach my $i(@$shows)
    {
        my $show        =   @$i[1];
        print "\n\t\"$show\"\n";
            $show =~ s/ /-/g;
        my $trakt_api   =   $config{trakt_api};
            my $url = "http://api.trakt.tv/show/seasons.json/$trakt_api/$show";
            my %show_episodes   = get_season_episodes($show);
                foreach my $j (keys %show_episodes)
                    {unless($j == "0") {
                        push @is,("@$i[0]|$show|$j");

                    }
                     
                    }
    }

return \@is;
}
    
sub build_episodes {
    my @is = @_;
    my @out;
        foreach my $x(sort @is)
                     {
                        my ($id,$show,$season) = split (/\|/,$x);
                        my $show_seasons = get_episodes_in_season($show,$season,$id);
                        foreach my $t(@$show_seasons) {
                        push @out,$t;
                        }

                            }
return \@out;
}


sub get_episodes_in_season {
    my $show = $_[0];
    my $season = $_[1];
    my $id      = $_[2];
    my @line;
    my %hash;
    my $url  = "http://api.trakt.tv/show/season.json/$config{trakt_api}/$show/$season";
    my $decode = JSON::XS->new->utf8->decode (get($url));
        foreach my $i(@$decode)
         {
            if(length($i->{season}) == 1) {$i->{season} = "0$i->{season}"}
            if(length($i->{episode}) == 1) {$i->{episode} = "0$i->{episode}"}
             my @tmp;
                 push @line,("$id|s$i->{season}e$i->{episode}|$i->{title}|$i->{overview}|$show");
                 print "$id|s$i->{season}e$i->{episode}|$i->{title}|$show\n";
         }
     
return \@line;

}

sub check_episode_exists {
    my @s_and_e = @_;
    my $return;
    my $dbh = new_dbh();
    my @inserts;
    my @updates;
    foreach my $sh(@s_and_e) {
                              my ($id,$format_name,$title,$overview,$show) = split(/\|/,$sh);
                                $show =~ s/-/ /g;
                              my $sth = $dbh->prepare("SELECT COUNT(*) from seasons
                                                      WHERE id = ?
                                                      and format_name =?");
                              $sth->execute($id,$format_name);
                              my $row = $sth->fetchrow();
                              $sth->finish;
                              if($row == "0") {
                                push @inserts,"$id|$format_name|$title|$overview";
                                }
                              if($row > 0) {
                                push @updates,("$id|$format_name|$overview|$title");
                                } 
                              }
 my $ins = insert_seasons2(@inserts);
 my $skip = update_overview2(\@updates);

return ($ins,$skip); 
    
}

sub update_overview2 {
    my $dbh =   new_dbh();
    my $cnt = 0;
    my $change = $_[0];
    my $sth = $dbh->prepare("UPDATE seasons
                            SET overview = ?, title = ?
                            WHERE id = ?
                            AND season = ?
                            AND episode = ?");
    foreach my $i(@$change){
        my ($id,$format_name,$overview,$title) = split (/\|/,$i);
        my $season = substr($format_name,0,3);
        my $episode = substr($format_name,3,3);


    $sth->execute($overview,$title,$id,$season,$episode);
    $cnt++;
    }
return $cnt;


}

sub insert_seasons2 {
    my $dbh = new_dbh();
    my @inserts = @_;
    my $sth = $dbh->prepare("INSERT INTO seasons
                            (id,showname,season,episode,title,overview,format_name,downloaded)
                            VALUES
                            (?,(select showname from watcher where id=?),?,?,?,?,?,'0')" );
    my $cnt=0;
    foreach my $i(@inserts){
      my ($id,$format_name,$title,$overview) = split(/\|/,$i);
      my $season = substr($format_name,0,3);
      my $episode = substr($format_name,3);
          
    $sth->execute($id,$id,$season,$episode,$title,$overview,$format_name);
    $cnt++
    }
return $cnt;
    
}

sub get_watcher_shows {
    my $dbh = new_dbh();
    my @shows;
    my $sth = $dbh->prepare("SELECT id,showname
                            FROM watcher");
    $sth->execute();
    while(my @rows = $sth->fetchrow_array() ) { 
        push @shows,\@rows;
        
    }
    return \@shows;
    $sth->finish;
}


sub get_season_episodes {
    my $show    =   $_[0];
    my $url     =   "http://api.trakt.tv/show/seasons.json/$config{trakt_api}/$show";
    my %details;
    my $get = get($url);
    if(!defined $get){print "\n!! ERROR!! - Skipping show \"$show\". No matches found. Check spelling?\n\nContinuing with other shows......\n";sleep(5)}
    else{
    my $decode = JSON::XS->new->utf8->decode ($get);
        foreach my $i (@$decode) {
            $details{$i->{season}} = $i->{episodes};
        }
    }
    
    return %details;    
}


sub get_myshow{
    my ($show_id,$showname,$format_name) = @_;
    my $show = "$showname $format_name";
    my $catid       = $config{catid};
    my $hits        = 1;
    my $larger      = $config{nzb_min_size_long};
    my $smaller     = $config{nzb_max_size_long};
    my $url         = $config{nzbmatrix_search_url};
    my $sab_api_url = "http://$config{sabnzb_ip}:$config{sabnzb_port}/sabnzbd/api?mode=addurl&apikey=$config{sabnzb_apikey}&name=";
    my $username    = $config{nzbmatrix_username};
    my $apikey      = $config{nzbmatrix_apikey};
    my $category    = $config{sabnzb_catrgory};
    my $get         = get("$url$show&catid=$catid&num=$hits&larger=$larger&smaller=$smaller&username=$username&apikey=$apikey");
         unless ($get eq "error:nothing_found" || $get eq "error:invalid_login")
        {
        my @nzb         = split ("\n",$get);
               $nzb[0] =~ s/;//;
        my($label,$id)  = split(":",$nzb[0]);
        my $send_to_sab = "$config{nzbmatrix_get_url}$id&username=$config{nzbmatrix_username}";
        $get = get("$sab_api_url$send_to_sab&cat=$category");
               if($get =~ m/ok/) {update_shows($show_id,$showname,$format_name)}
               else{$get = "Failed sending to SabNZB. Is you configure setup correctly?"}
     }
    if($get eq "error:invalid_login"){$get = "No results. Incorrect NZBMatrix username or API. Have you set them up in your config?"}    
    if($get eq "error:nothing_found"){$get = "There was no download available for this show. This is normal if the show hasn't aired yet"}
    return $get;
}


sub shows_for_download{
    my $dbh = new_dbh();
    my @return;
    my $sth = $dbh->prepare("SELECT id,showname,format_name
                            FROM seasons
                            WHERE downloaded IS NOT 1");
    $sth->execute();
    while(my @row = $sth->fetchrow_array() ){
        push @return,\@row
    }
    
return \@return;    
}

sub new_dbh {
    my $db_path;
    if(length $diggy_path =="0"){$db_path="./"}
    else{$db_path = $diggy_path}
    my $dbfile = "shows.db";
    my $dbh= DBI->connect("DBI:SQLite:dbname=$db_path$dbfile","","",{sqlite_use_immediate_transaction => 1,AutoCommit => 1,RaiseError => 1, PrintError => 1,}) or die $DBI::errstr;
    $dbh->do("PRAGMA synchronous = OFF");
    $dbh->{TraceLevel} = 0;
    return $dbh;
}


sub read_config {
         my $dbh = new_dbh();
         my ($trakt_api,
             $nzbmatrix_search_url,
             $nzbmatrix_get_url,
             $nzbmatrix_username,
             $nzbmatrix_apikey,
             $sabnzb_ip,
             $sabnzb_port,
             $sabnzb_apikey,
             $nzb_catid,
             $nzb_min_size_long,
             $nzb_max_size_long,
             $sabnzb_catrgory);
         my $sth = $dbh->prepare("select trakt_api,nzbmatrix_search_url,nzbmatrix_get_url,nzbmatrix_username,
                                 nzbmatrix_apikey,sabnzb_ip,sabnzb_port,sabnzb_apikey,nzb_catid,
                                 nzb_min_size_long,nzb_max_size_long,sabnzb_catrgory from config");
         $sth->execute();
         $sth->bind_columns (\$trakt_api,\$nzbmatrix_search_url,\$nzbmatrix_get_url,\$nzbmatrix_username,\$nzbmatrix_apikey,\$sabnzb_ip,
                             \$sabnzb_port,\$sabnzb_apikey,\$nzb_catid,\$nzb_min_size_long,\$nzb_max_size_long,\$sabnzb_catrgory);
         $sth->bind_col( 1, \$trakt_api );
         $sth->bind_col( 2, \$nzbmatrix_search_url );
         $sth->bind_col( 3, \$nzbmatrix_get_url );
         $sth->bind_col( 4, \$nzbmatrix_username );
         $sth->bind_col( 5, \$nzbmatrix_apikey);
         $sth->bind_col( 6, \$sabnzb_ip );
         $sth->bind_col( 7, \$sabnzb_port );
         $sth->bind_col( 8, \$sabnzb_apikey );
         $sth->bind_col( 9, \$nzb_catid );
         $sth->bind_col( 10, \$nzb_min_size_long );
         $sth->bind_col( 11, \$nzb_max_size_long );
         $sth->bind_col( 12, \$sabnzb_catrgory );
         $sth->fetch();

my %config = (
              'trakt_api'               =>      $trakt_api,
              'nzbmatrix_search_url'    =>      $nzbmatrix_search_url,
              'nzbmatrix_get_url'       =>      $nzbmatrix_get_url,
              'nzbmatrix_username'      =>      $nzbmatrix_username,
              'nzbmatrix_apikey'        =>      $nzbmatrix_apikey,
              'sabnzb_ip'               =>      $sabnzb_ip,
              'sabnzb_port'             =>      $sabnzb_port,
              'sabnzb_apikey'           =>      $sabnzb_apikey,
              'sabnzb_catrgory'         =>      $sabnzb_catrgory,
              'nzb_catid'               =>      $nzb_catid,
              'nzb_min_size_long'       =>      $nzb_min_size_long,
              'nzb_max_size_long'       =>      $nzb_max_size_long
             
              );
return %config;

}

sub get_config {
         my $dbh = new_dbh();
         my ($nzbmatrix_username,
             $nzbmatrix_apikey,
             $sabnzb_ip,
             $sabnzb_port,
             $sabnzb_apikey,
             $nzb_catid,
             $nzb_min_size_long,
             $nzb_max_size_long,
             $sabnzb_catrgory);
         my $sth = $dbh->prepare("select nzbmatrix_username,nzbmatrix_apikey,sabnzb_ip,sabnzb_port,sabnzb_apikey,nzb_catid,nzb_min_size_long,nzb_max_size_long,sabnzb_catrgory from config");
         $sth->execute();
         $sth->bind_columns (\$nzbmatrix_username,\$nzbmatrix_apikey,\$sabnzb_ip,\$sabnzb_port,\$sabnzb_apikey,\$nzb_catid,\$nzb_min_size_long,\$nzb_max_size_long,\$sabnzb_catrgory);
         $sth->bind_col( 1, \$nzbmatrix_username );
         $sth->bind_col( 2, \$nzbmatrix_apikey);
         $sth->bind_col( 3, \$sabnzb_ip );
         $sth->bind_col( 4, \$sabnzb_port );
         $sth->bind_col( 5, \$sabnzb_apikey );
         $sth->bind_col( 6, \$nzb_catid );
         $sth->bind_col( 7, \$nzb_min_size_long );
         $sth->bind_col( 8, \$nzb_max_size_long );
         $sth->bind_col( 9, \$sabnzb_catrgory );
         while ($sth->fetch() ) {

       return($nzbmatrix_username,
             $nzbmatrix_apikey,
             $sabnzb_ip,
             $sabnzb_port,
             $sabnzb_apikey,
             $nzb_catid,
             $nzb_min_size_long,
             $nzb_max_size_long,
             $sabnzb_catrgory);
         }

}

sub update_config {
         my($new_nzbmatrix_username,$new_nzbmatrix_apikey,$new_sabnzb_ip,
             $new_sabnzb_port,$new_sabnzb_apikey,$new_nzb_catid,$new_nzb_min_size_long,
             $new_nzb_max_size_long,$new_sabnzb_catrgory,$initial) = @_;
         my $dbh = new_dbh();
         my $sth = $dbh->prepare("UPDATE config set
                                 nzbmatrix_username = ?,
                                 nzbmatrix_apikey = ?,
                                 sabnzb_ip = ?,
                                 sabnzb_port = ?,
                                 sabnzb_apikey = ?,
                                 nzb_catid = ?,
                                 nzb_min_size_long = ?,
                                 nzb_max_size_long = ?,
                                 sabnzb_catrgory = ?,
                                 initial = ?                                 
                                 ");
         $sth->execute($new_nzbmatrix_username,$new_nzbmatrix_apikey,$new_sabnzb_ip,
                       $new_sabnzb_port,$new_sabnzb_apikey,$new_nzb_catid,$new_nzb_min_size_long,
                       $new_nzb_max_size_long,$new_sabnzb_catrgory,$initial);


}
sub check_config{
    my $dbh = new_dbh();
    my $return;
    my $sth = $dbh->prepare("select initial from config");
    $sth->execute();
    my $set = $sth->fetchrow();
    
    return $set;
    
}


sub run_config {
 
         my @newconfig;
         my ($nzbmatrix_username,
             $nzbmatrix_apikey,
             $sabnzb_ip,
             $sabnzb_port,
             $sabnzb_apikey,
             $nzb_catid,
             $nzb_min_size_long,
             $nzb_max_size_long,
             $sabnzb_catrgory) = get_config();
         print "Enter your NZBMatrix Username [$nzbmatrix_username]: ";
         chomp (my $new_nzbmatrix_username = <STDIN>);
                  if(length $new_nzbmatrix_username =="0") {$new_nzbmatrix_username = $nzbmatrix_username}
         print "Enter your NZBMatrix API Key (viewable in your online account) [$nzbmatrix_apikey]: ";
         chomp (my $new_nzbmatrix_apikey = <STDIN>);
                  if(length $new_nzbmatrix_apikey =="0") {$new_nzbmatrix_apikey = $nzbmatrix_apikey}
         print "Enter the IP address of your SabNZBd Server [$sabnzb_ip]: ";
         chomp (my $new_sabnzb_ip = <STDIN>);
                  if(length $new_sabnzb_ip =="0") {$new_sabnzb_ip = $sabnzb_ip}
         print "Enter the port your SabNZBd Server is listening on [$sabnzb_port]: ";
         chomp (my $new_sabnzb_port = <STDIN>);
                  if(length $new_sabnzb_port =="0") {$new_sabnzb_port = $sabnzb_port}
         print "Enter your SabNZBD APIKEY (you will find this in the Sabnzbd Config: [$sabnzb_apikey] ";
         chomp (my $new_sabnzb_apikey = <STDIN>);
                  if(length $new_sabnzb_apikey =="0") {$new_sabnzb_apikey = $sabnzb_apikey}
         print "Enter the category id you'd like to search on e.g \"41\" is HD (x264) [$nzb_catid]: ";
         chomp (my $new_nzb_catid = <STDIN>);           
                  if(length $new_nzb_catid =="0") {$new_nzb_catid = $nzb_catid}
         print "Enter the category name you'd like to save your shows under in SabNZBd [$sabnzb_catrgory]: ";
         chomp (my $new_sabnzb_catrgory = <STDIN>);           
                  if(length $new_sabnzb_catrgory =="0") {$new_sabnzb_catrgory = $sabnzb_catrgory}
         print "Enter the smallest size show you would like to download in MB [$nzb_min_size_long]: ";
         chomp (my $new_nzb_min_size_long = <STDIN>); 
                  if(length $new_nzb_min_size_long  =="0") {$new_nzb_min_size_long  = $nzb_min_size_long }
         print "Enter the largest size show you would like to download in MB [$nzb_max_size_long]: ";
         chomp (my $new_nzb_max_size_long = <STDIN>); 
                  if(length $new_nzb_max_size_long  =="0") {$new_nzb_max_size_long  = $nzb_max_size_long }

update_config($new_nzbmatrix_username,$new_nzbmatrix_apikey,$new_sabnzb_ip,
             $new_sabnzb_port,$new_sabnzb_apikey,$new_nzb_catid,$new_nzb_min_size_long,
             $new_nzb_max_size_long,$new_sabnzb_catrgory,"1");

}