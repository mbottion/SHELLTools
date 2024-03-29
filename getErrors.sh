die()
{
  echo "
   ERREUR : $*
  "
 exit 1
}
usage()
{
  echo "Usage
  
  $(basename $0) [-h] [-l] [-D days] [file]

    NOTE : POSITIONAL parameters

    ORACLE Trace file analysis. Trace file can be the online alert.log or a zipped one
  by default it takes the alert-log of the current database.

    -l : Local node only
    -D : Days to analyze (1: Today, 2: Today & Yesterday ... , ALL: All the file)

    If the alert.log is to be analyzed, we try to access the alert.log of the second instance too"
 exit 1
}
DAYS=1
[ "$1" = "-?" -o "$1" = "-h" ] && usage
[ "$1" = "-l" ] && { LOCAL=Y ; shift ; }
[ "$1" = "-D" ] && { DAYS=$2 ; daysParameter="-D $DAYS" ; shift 2 ; }
[ "${DAYS^^}" = "ALL" ] && DAYS=10000 
file=$1
[ "$file" = "" -a -f $ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log ] \
               && { upper=Y ; file=$ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log ; }
[ "$file" = "" -a -f $ORACLE_BASE/diag/rdbms/${ORACLE_UNQNAME,,}/$ORACLE_SID/trace/alert_$ORACLE_SID.log ] \
               && { upper=N ; file=$ORACLE_BASE/diag/rdbms/${ORACLE_UNQNAME,,}/$ORACLE_SID/trace/alert_$ORACLE_SID.log ; }
[ "$file" = "" ] && die "Fichier trace non specifie"
[ ! -f $file ] && die  "Fichier $1 introuvable"
f=$(basename $file)

if [ "$(file $file | egrep -i "UTF-8|ASCII|Text")" = "" ]
then
  cmd="zcat $file"
else
  cmd="cat $file"
fi
ANALYZE_CURRENT_ALERT=N
fullFile=$(readlink -f $file)
if  [ "$fullFile" = "$ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log" -o \
      "$fullFile" = "$ORACLE_BASE/diag/rdbms/${ORACLE_UNQNAME,,}/$ORACLE_SID/trace/alert_$ORACLE_SID.log" ]
then
  ANALYZE_CURRENT_ALERT=Y
fi

RED_NORM="$(tput setaf 1)"
RED_BOLD="$(tput bold ;tput setaf 1)"
GREEN_NO="$(tput setaf 2)"
NORM="$(tput sgr0)"
echo ""
echo "--+--- Fichier trace: $f ($(hostname))"
echo "  |"
eval $cmd  | \
  sed -e "s;\(ospid *[0-9]*\);(ospid NNNNNN);" | \
  awk '
BEGIN {jour="";test_print=0; error=""; nb=0;today="'$(date +%Y%m%d)'";min_date=today-'$DAYS'+1; to_print="Y"}
/ORA-0$/ {next}
/in tablespace SYSAUX/ {next}
/Patch Description/ {next}
/ORA-/ { 
  error=$0 
  getline $0
  while ( $0 ~ /ORA-/ )
  {
    error=sprintf("%s\n  |   |                            > %s",error,$0)
    getline $0
  }
}
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
  heure=substr($0,12)
  jour_prec=jour
  jour=substr($0,1,10)
  jour_num=sprintf("%s%s%s",substr(jour,1,4),substr(jour,6,2), substr(jour,9,2))
  jour_num=jour_num+0
#  printf("                           - %s\n",$0)
  test_print=1
}
/Starting ORACLE instance/                                              { error=sprintf("'${GREEN_NO}'*** INSTANCE       START *** '${NORM}': %s",$0) }
/Instance shutdown complete/                                            { error=sprintf("'${RED_NORM}'*** INSTANCE STOP        *** '${NORM}': %s",$0) }
/terminating the instance/                                              { error=sprintf("'${RED_BOLD}'*** INSTANCE CRASH       *** '${NORM}': %s",$0) }
/Background Media Recovery process shutdown/                            { error=sprintf("'${RED_BOLD}'*** REDO APPLY STOP      *** '${NORM}': %s",$0) }
/Completed: ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT/ { error=sprintf("'${GREEN_NO}'*** REDO APPLY     START *** '${NORM}': %s",$0) }
{
  if ( test_print==1)
  {
    if (jour != jour_prec) 
    {
      if ( jour_num+0 >= min_date+0 ) { to_print="Y" } else { to_print="N" }
      if ( nb > 1 )
      {
        printf("  |   |                              (repetee %d fois, jusqu a %s)\n",nb,heure)
        nb=0
        prev_error=""
      }
      if ( to_print == "Y" )
      {
        printf("  |          \n")
        printf("  +---+-- %s ('$(hostname -s)' --> Analyzed : %s)\n",jour,to_print)
        printf("  |   |\n")
      }
      else
      {
        printf("  +---+-- %s ('$(hostname -s)' --> Analyzed : %s Use -d DAYS if needed)\n",jour,to_print)
      }
    }
    if (error != "" && to_print == "Y")
    {
      if ( error==prev_error)
      {
        nb++
      }
      else
      {
        if ( nb > 1 )
        {
          printf("  |   |                              (repetee %d fois, jusqu a %s)\n",nb,heure)
          printf("  |   |      \n")
          nb=0
          prev_error=""
        }
        printf("  |   +--> %s ==> %s\n",heure,error)
        prev_error=error
        nb=1
        error=""
      }
    }
    test_print=0
  }
}
' 

if [ "$LOCAL" != "Y" -a "$ANALYZE_CURRENT_ALERT" = "Y" ]
then
  localServer=$(hostname -f)
  scriptPath=$(readlink -f $0)
  if    [[ "$localServer" =~ ^[^\.]*1\. ]]
  then
    autreNoeud=$(echo $localServer | sed -e "s;^\([^\.]*\)1;\12;")
    autreSID=$(echo $ORACLE_SID | sed -e "s;^\([^\.]*\)1;\12;")
  elif  [[ "$localServer" =~ ^[^\.]*2\. ]]
  then
    autreNoeud=$(echo $localServer | sed -e "s;^\([^\.]*\)2;\11;")
    autreSID=$(echo $ORACLE_SID | sed -e "s;^\([^\.]*\)1;\11;")
  else
    die "Nom de serveur non connu"
  fi
  if [ "$upper" = "Y" ]
  then
    autreAlert=$ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$autreSID/trace/alert_$autreSID.log
  else
    autreAlert=$ORACLE_BASE/diag/rdbms/${ORACLE_UNQNAME,,}/$autreSID/trace/alert_$autreSID.log
  fi


  echo
  echo "======================================================================"
  echo "Copie et lancement de $scriptPath sur $autreNoeud ($daysParameter)"
  echo "======================================================================"
  echo

  ssh -o StrictHostKeyChecking=no $autreNoeud true || die "$autre Noeud non accessible"
  ssh -o StrictHostKeyChecking=no $autreNoeud mkdir -p $(dirname $scriptPath) || die "Impossible de creer le repertoire"
  ssh -o StrictHostKeyChecking=no $autreNoeud test -f $autreAlert || die "$autreAlert non trouve sur $autreNoeud"
  scp -o StrictHostKeyChecking=no -q $scriptPath ${autreNoeud}:$scriptPath || die "Impossible de recopier le script"
  envFile=/home/oracle/$(echo $ORACLE_SID | sed -e "s;.$;;").env
  ssh -o StrictHostKeyChecking=no $autreNoeud "ORACLE_SID=None ; . $envFile ; export LOCAL=Y export REMOTE=Y ; $scriptPath $daysParameter $autreAlert"
  ssh -o StrictHostKeyChecking=no $autreNoeud rm -f $scriptPath || die "Impossible de supprimer le script copie"

fi

if [ "$REMOTE" != "Y" ]
then
  echo "

   Trace file analysis completed:
   =============================
    "
  echo "   $localServer : $file"
[ "$autreNoeud" != "" ] && echo "   $autreNoeud : $autreAlert"
  echo "
   ============================="
fi
