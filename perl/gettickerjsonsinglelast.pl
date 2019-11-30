#!/usr/bin/perl
use strict;
use warnings;
use lib qw(/home/tickerlick/cgi-bin);
use LWP::Simple;
my ($DBPASSWORD) = $ENV{DBPASSWORD};
my ($DBUSER) = $ENV{DBUSER};
use DBI;
use JSON;
use Data::Dumper;
use strict;
use warnings;
my ($dbh,$sth2,$sth1);
#my ($PASSWORD) = $ENV{DBPASSWORD};
$dbh = DBI->connect('dbi:mysql:tickmaster',$DBUSER,$DBPASSWORD) or die "Connection Error: $DBI::errstr\n";
#my (%tick) = getResultsjson($ARGV[0]);
sub getResultsjson
{
my ($ticker) = uc shift;
my (%tickhash,$key) ;
my $sql = "select count(*) from tickermaster where ticker = '$ticker'";
my $sth2 = $dbh->prepare($sql);
$sth2->execute or die "SQL Error: $DBI::errstr\n";
my @row = $sth2->fetchrow_array;
if (!$row[0] || $row[0] < 1)
{
  $tickhash{invalidticker} = 1;
  $sth2->finish;
  return %tickhash;
}
$sth2->finish;
#prefix '^' for indices
if ($ticker eq 'VIX')
{
   $ticker = '^VIX';
}
my $url = 'https://query.yahooapis.com/v1/public/yql?q=select%20YearLow,OneyrTargetPrice,DividendShare,ChangeFromFiftydayMovingAverage,FiftydayMovingAverage,PercentChangeFromTwoHundreddayMovingAverage,DaysLow,DividendYield,ChangeFromYearLow,ChangeFromYearHigh,EarningsShare,LastTradePriceOnly,YearHigh,LastTradeDate,PreviousClose,Volume,MarketCapitalization,Name,DividendPayDate,ExDividendDate,PERatio,PercentChangeFromFiftydayMovingAverage,ChangeFromTwoHundreddayMovingAverage,DaysHigh,PercentChangeFromYearLow,TwoHundreddayMovingAverage,PercebtChangeFromYearHigh,Open,Symbol%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'.$ticker.'%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=';
if ($ticker eq '^VIX')
{
   $ticker = 'VIX';
}
my ($v);
my   $content = get($url);
#if ($content)
#{
my $obj = from_json($content);
#if ($content =~ m/Day\'s Range<\/th><td>N\/A/)
#{
# $tickhash{invalidticker} = 1;
# return %tickhash;
#}
my($str) = $obj->{'query'}->{'results'}->{'quote'};
#print Dumper($str);
#my %text = decode_json(Dumper($str));
#if ($str->{'Name'} &&$str->{'LastTradePriceOnly'})
#{
#foreach $key (keys %$str)
#{
#    $str->{$key} =~ s/\+|\%//g;
#    #if (!$str->{$key}){$str->{$key} = NULL;}
#}
#print Dumper($str);
#$str->{Symbol} =~ s/\^//g;
$str->{Symbol} = $ticker;
$content = get("http://www.marketwatch.com/investing/stock/$ticker");
$content =~ s/\r\n//g;
if ($content =~ /.*?<span class\=\"volume last\-value\">(.*?)<\/span>.*?<span class\=\"last\-value\">(.*?)<\/span>.*?<span class\=\"text low\">(.*?)<\/span>.*?<span class\=\"text high\">(.*?)<\/span>.*?<span class\=\"text low\">(.*?)<\/span>.*?<span class\=\"text high\">(.*?)<\/span>/s)
{
   my $v = $1;
   #print "$m,$2,$3,$4,$5,$6\n";
   $str->{'YearHigh'} = $6;
   $str->{'YearLow'} = $5;
   $str->{'DaysHigh'} = $4; 
   $str->{'DaysLow'} = $3;
   $str->{'LastTradePriceOnly'} = $2;
   $v =~ s/\s+//g;
   if ($v =~ /.*K$/){$v *= 1000;}
   elsif ($v =~ /.*M$/){$v *= 1000000;}
   elsif ($v =~ /.*B$/){$v *= 1000000000;}
   $str->{'Volume'} = $v;
}
if ($str->{'MarketCapitalization'} =~ /(.*)B$/)
{
    $str->{'MarketCapitalization'} = $1 * 1000;
}
elsif ($str->{'MarketCapitalization'} =~ /(.*)K$/)
{
    $str->{'MarketCapitalization'} = $1 *0.001;
}
elsif ($str->{'MarketCapitalization'} =~ /(.*)M$/)
{
    $str->{'MarketCapitalization'} = $1;
}
my ($m,$d,$y) = split (/\//,$str->{'LastTradeDate'});
if ($m > 0)
{
$str->{'LastTradeDate'} = $y."-".$m."-".$d;
}
($m,$d,$y) = split (/\//,$str->{'DividendPayDate'});
if ($m > 0)
{
$str->{'DividendPayDate'} = $y."-".$m."-".$d;
}
($m,$d,$y) = split (/\//,$str->{'ExDividendDate'});
if ($m > 0)
{
$str->{'ExDividendDate'} = $y."-".$m."-".$d;
}
$str->{'Name'} =~ s/\'|\"//g;
$str->{'Name'} = "'".$str->{'Name'}."'";
$str->{'Symbol'} = "'".$str->{'Symbol'}."'";
$str->{'LastTradeDate'} = "'".$str->{'LastTradeDate'}."'";
$str->{'DividendPayDate'} = "'".$str->{'DividendPayDate'}."'";
$str->{'ExDividendDate'} = "'".$str->{'ExDividendDate'}."'";
#my ($cols) = "YearLow,OneyrTargetPrice,DividendShare,ChangeFromFiftydayMovingAverage,FiftydayMovingAverage,PercentChangeFromTwoHundreddayMovingAverage,DaysLow,DividendYield,ChangeFromYearLow,ChangeFromYearHigh,EarningsShare,LastTradePriceOnly,YearHigh,LastTradeDate,PreviousClose,Volume,MarketCapitalization,Name,DividendPayDate,ExDividendDate,PERatio,PercentChangeFromFiftydayMovingAverage,ChangeFromTwoHundreddayMovingAverage,DaysHigh,PercentChangeFromYearLow,TwoHundreddayMovingAverage,PercebtChangeFromYearHigh,Open,Symbol";
my ($query);
#$query = "REPLACE INTO tickerpricefun (YearLow,OneyrTargetPrice,DividendShare,ChangeFromFiftydayMA,DaysLow,FiftydayMA,EarningsShare,LastTradePrice,YearHigh,LastTradeDate,Symbol,PreviousClose,Volume,PERatio,MarketCap,Name,PercentChangeFromTwoHundreddayMA,DividendPayDate,ChangeFromYearHigh,PercentChangeFromFiftydayMA,ChangeFromTwoHundreddayMA,DaysHigh,PercentChangeFromYearLow,PercentChangeFromYearHigh,DividendYield,ChangeFromYearLow,ExDividendDate,TwoHundreddayMA,Open)  values ($str->{'YearLow'},$str->{'OneyrTargetPrice'},$str->{'DividendShare'},$str->{'ChangeFromFiftydayMovingAverage'},$str->{'DaysLow'},$str->{'FiftydayMovingAverage'},$str->{'EarningsShare'},$str->{'LastTradePriceOnly'},$str->{'YearHigh'},$str->{'LastTradeDate'},$str->{'Symbol'},$str->{'PreviousClose'},$str->{'Volume'},$str->{'PERatio'},$str->{'MarketCapitalization'},$str->{'Name'},$str->{'PercentChangeFromTwoHundreddayMovingAverage'},$str->{'DividendPayDate'},$str->{'ChangeFromYearHigh'},$str->{'PercentChangeFromFiftydayMovingAverage'},$str->{'ChangeFromTwoHundreddayMovingAverage'},$str->{'DaysHigh'},$str->{'PercentChangeFromYearLow'},$str->{'PercebtChangeFromYearHigh'},$str->{'DividendYield'},$str->{'ChangeFromYearLow'},$str->{'ExDividendDate'},$str->{'TwoHundreddayMovingAverage'},$str->{'Open'})";
   #print "tom::$query\n";
# $sth1 = $dbh->prepare($query);
# $sth1->execute or die "SQL Error: $DBI::errstr\n";
# $sth1->finish;
#$Ticker,$LastTrade,$PrevClose,$yTargetEst,$wkRange,$vol,$MarketCap,$PE,$EPS
 %tickhash = transformtickerdetjson($str,$str->{'Symbol'},$str->{'LastTradePriceOnly'},$str->{'PreviousClose'},$str->{'OneyrTargetPrice'},$str->{'Volume'},$str->{'YearLow'},$str->{'YearHigh'},$str->{'MarketCapitalization'},$str->{'PERatio'},$str->{'EarningsShare'});
# %tickhash = transformtickerdet1($str);
#}
#}
return %tickhash;
}


sub transformtickerdetjson
{
   my ($tickerhash) = shift; 
   my ($Ticker,$LastTrade,$PrevClose,$yTargetEst,$wkRange,$vol,$MarketCap,$PE,$EPS,$DividendYield,$EnterpriseValue,$TrailingPE,$ForwardPE,$PEGRatio,$PriceSales,$PriceBook,$EnterpriseValueRevenue,$EnterpriseValueEBITDA,$FiscalYearEnds,$MostRecentQuarter,$OperatingMargin,$ReturnonAssets,$ReturnonEquity,$Revenue,$RevenuePerShare,$QtrlyRevenueGrowth,$GrossProfit,$EBITDAttm,$NetIncomeAvltoCommon,$DilutedEPS,$QtrlyEarningsGrowth,$TotalCash,$TotalCashPerShare,$TotalDebt,$TotalDebtEquity,$CurrentRatio,$BookValuePerShare,$OperatingCashFlow,$LeveredFreeCashFlow,$Beta,$WeekChange,$SP50052WeekChange,$WeekHigh,$WeekLow,$fiftyDayMovingAverage,$twohundredDayMovingAverage,$SharesOutstanding,$SharesShort,$PayoutRatio,$exdividenddate,$diff,$perdiff,$diffhigh,$difflow,$perdifflow,$perdiffhigh,);
    ($Ticker,$LastTrade,$PrevClose,$yTargetEst,$vol,$WeekLow,$WeekHigh,$MarketCap,$PE,$EPS)= @_;
    my ($flag) = 0;
    if ($LastTrade == 0) {return 0;}
    $wkRange = $WeekLow ."-".$WeekHigh;

   $diff = '';
   if  ($wkRange =~ /A/)
    {
       $diff = "N\/A";
       $perdiff =    "N\/A";
    }
   elsif (   $wkRange =~ /(.*?)-(.*)/)
   {
       $tickerhash->{YearLow} = $WeekLow; 
       $tickerhash->{YearHigh} = $WeekHigh; 
       $diffhigh = $tickerhash->{YearHigh} - $LastTrade;
       if ($tickerhash->{YearHigh}) {$perdiffhigh = abs(($diffhigh/$tickerhash->{YearHigh})) * 100;}
       $tickerhash->{diffhigh} = sprintf("%.2f", $diffhigh);
       $tickerhash->{perdiffhigh} = abs(sprintf("%.2f", $perdiffhigh));
       $difflow = $tickerhash->{YearLow} - $LastTrade;
       if ($tickerhash->{YearLow}){$perdifflow = abs(($difflow/$tickerhash->{YearLow})) * 100;}
       $tickerhash->{difflow} = sprintf("%.2f", $difflow);
       $tickerhash->{perdifflow} = abs(sprintf("%.2f", $perdifflow));
       if ($tickerhash->{diffhigh} > 0)
       {
        $tickerhash->{diffhighstat} = "down";
       }
else
        {
           $tickerhash->{diffhighstat} = "up";
        }

       if ($tickerhash->{difflow} > 0)
{
        $tickerhash->{difflowstat} = "down";
       }
        else
        {
           $tickerhash->{difflowstat} = "up";
        }
   }
$tickerhash->{diffhigh} = abs($tickerhash->{diffhigh});
$tickerhash->{difflow} = abs($tickerhash->{difflow});
$tickerhash->{PrevClose} = $PrevClose;
$tickerhash->{wkRange} = $wkRange;
#$tickerhash->{DividendYield} = $DivYield;
#$tickerhash->{Beta} = $Beta;
$tickerhash->{PE} = $PE;
$tickerhash->{ForwardPE} = $ForwardPE;
$tickerhash->{EPS} = $EPS;
$tickerhash->{yTargetEst} = $yTargetEst;
$tickerhash->{vol} = $vol;
$tickerhash->{LastTrade} = $LastTrade;
$tickerhash->{Ticker} = $Ticker;
$tickerhash->{MarketCap} = $MarketCap;
$tickerhash->{class} = "Common Stock";
$tickerhash->{pricediff} = abs($tickerhash->{LastTrade} - $tickerhash->{PrevClose});
$tickerhash->{pricediff} = sprintf("%.2f", $tickerhash->{pricediff});
if ($tickerhash->{PrevClose}) {$tickerhash->{pricediffper} = abs(sprintf("%.2f",($tickerhash->{pricediff}/$tickerhash->{PrevClose}) * 100));}
#print "tom:$tickerhash->{pricediff},$tickerhash->{LastTrade},$tickerhash->{PrevClose},$tickerhash->{pricediffper}\n";
if ($tickerhash->{PrevClose} < $tickerhash->{LastTrade})
{
  $tickerhash->{PriceStat} = "up";
}
else
{
  $tickerhash->{PriceStat} = "down";
}
 my (@row,$ticker_id,$lasttrade,$key);
 my $sql = "select ticker_id,comp_name,sector,industry,tflag2 from tickermaster where ticker = $tickerhash->{Ticker}";
#print "tom1:$sql\n";
 my  $sth = $dbh->prepare($sql);
 $sth->execute or die "SQL Error: $DBI::errstr\n";
 while (@row = $sth->fetchrow_array) {
  $ticker_id = $row[0];
  $tickerhash->{name} = $row[1];
  $tickerhash->{sector} = $row[2];
  $tickerhash->{industry} = $row[3];
  $tickerhash->{tflag} = $row[4];
if (!$ticker_id)
{
 $tickerhash->{dma10} = "N\/A";;
 $tickerhash->{dma50} = "N\/A";
 $tickerhash->{dma200} = "N\/A";
}
}
if ($ticker_id)
{
 $sql ="select dma_10, dma_50, dma_200 from tickerprice a where a.ticker_id = $ticker_id ORDER BY a.price_date DESC LIMIT 0,1;";
#print "tom2:$sql\n";
 $sth = $dbh->prepare($sql);
 $sth->execute or die "SQL Error: $DBI::errstr\n";
 while (@row = $sth->fetchrow_array)
 {
  $tickerhash->{dma10} = $row[0] || "N\/A";
  $tickerhash->{dma50} = $row[1] || "N\/A";
  $tickerhash->{dma200} = $row[2] || "N\/A";
  $flag = 1;
}
}
 $sth->finish;
 #$dbh->disconnect;
 if (!$flag)
{
 $tickerhash->{dma10} = "N\/A";;
 $tickerhash->{dma50} = "N\/A";
 $tickerhash->{dma200} = "N\/A";
}
else
{
 $tickerhash->{dma10diff} = abs(sprintf("%.2f", $tickerhash->{dma10} - $tickerhash->{LastTrade}));
 if ($tickerhash->{dma10}  && $tickerhash->{dma10} > 0)
{
 $tickerhash->{dma10diffper} = abs(sprintf("%.2f",($tickerhash->{dma10diff}/$tickerhash->{dma10}) * 100));
}
 $tickerhash->{dma50diff} = abs(sprintf("%.2f", $tickerhash->{dma50} - $tickerhash->{LastTrade}));
 if ($tickerhash->{dma50}  && $tickerhash->{dma50} > 0)
{
 $tickerhash->{dma50diffper} = abs(sprintf("%.2f",($tickerhash->{dma50diff}/$tickerhash->{dma50}) * 100));
}
 $tickerhash->{dma200diff} = abs(sprintf("%.2f", $tickerhash->{dma200} - $tickerhash->{LastTrade}));
if ($tickerhash->{dma200} && $tickerhash->{dma200} > 0)
{
 $tickerhash->{dma200diffper} = abs(sprintf("%.2f",($tickerhash->{dma200diff}/$tickerhash->{dma200}) * 100));
}
$lasttrade = $tickerhash->{LastTrade};
 if ($tickerhash->{dma10} < $lasttrade)
 {
  $tickerhash->{dma10stat} = "up";
 }
 else
 {
  $tickerhash->{dma10stat} = "down";
 }
 if ($tickerhash->{dma50} < $lasttrade)
 {
  $tickerhash->{dma50stat} = "up";
 }
 else
 {
  $tickerhash->{dma50stat} = "down";
 }
 if ($tickerhash->{dma200} < $lasttrade)
 {
  $tickerhash->{dma200stat} = "up";
 }
 else
 {
  $tickerhash->{dma200stat} = "down";
 }
}
foreach $key (keys %$tickerhash)
{
    if (defined $tickerhash->{$key}){next;}
    $tickerhash->{$key} = ' ';
}
return %$tickerhash
}
1;
