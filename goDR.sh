listServers()
{
cat <<%%
parx01-zf5km-n50ir1.oci.michelin.com;frax01-audry1.oci.michelin.com
parx01-zf5km-n50ir2.oci.michelin.com;frax01-audry2.oci.michelin.com
parx01-zf5km-n50ir3.oci.michelin.com;frax01-audry3.oci.michelin.com
lnx004016.oci.michelin.com;lnx004046.oci.michelin.com
lnx004000.oci.michelin.com;lnx004030.oci.michelin.com
lnx004001.oci.michelin.com;lnx004031.oci.michelin.com
lnx004006.oci.michelin.com;lnx004036.oci.michelin.com
lnx004007.oci.michelin.com;lnx004037.oci.michelin.com
lnx004010.oci.michelin.com;lnx004040.oci.michelin.com
lnx004011.oci.michelin.com;lnx004041.oci.michelin.com
lnx004019.oci.michelin.com;lnx004049.oci.michelin.com
lnx004020.oci.michelin.com;lnx004050.oci.michelin.com
lnx004025.oci.michelin.com;lnx004055.oci.michelin.com
%%
}

local=$(hostname -s)
line=$(listServers | grep $local)
par=$(echo $line | cut -f1 -d";")
fra=$(echo $line | cut -f2 -d";")

par_s=$(echo $par | cut -f1 -d".")
fra_s=$(echo $fra | cut -f1 -d".")

if [ "$local" = "$par_s" ]
then
  echo "LOCAL = PARIS ($par), jumping to FRANKFURT ($fra)"
  ssh $fra
elif [ "$local" = "$fra_s" ]
then
  echo "LOCAL = FRANKFURT ($fra), jumping to paris ($par)"
  ssh $par
else
  echo "unknown host : $local"
fi
