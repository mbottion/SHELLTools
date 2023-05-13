start_day=2023-04-19
end_day=$(date +%Y-%m-%d -d tomorrow)
echo "Days from $start_day to $end_day"


current_day=$start_day
while [ "$current_day" != "$end_day" ]
do
  next_day=$(date +%Y-%m-%d -d "$current_day + 1 days")
  s1=$(date +%d/%m/%Y -d $current_day)
  s2=$(date +%Y%m%d -d $current_day)
  e1=$(date +%d/%m/%Y -d $next_day)
  e2=$(date +%Y%m%d -d $next_day)
  outTxt=SQLDurationPerUser_${s2}.txt
  outHtml=SQLDurationPerUser_${s2}.html
  #echo "============================================"
  #echo "Statements duration per user on : $s2"
  #echo "============================================"
  #runScript.sh -O $outTxt     -s stmtAnalysis_duration.sql  "$s1 00:00:00" "$e1 00:00:00"
  #runScript.sh -O $outHtml -H -s stmtAnalysis_duration.sql  "$s1 00:00:00" "$e1 00:00:00"
  echo "============================================"
  echo "AWR reports on : $s2"
  echo "============================================"
  runScript.sh -s -O AWR_${s2}_full.html    -H getAwr.sql "$s1 00:00:00" "$e1 00:00:00"
  runScript.sh -s -O AWR_${s2}_00h_04h.html -H getAwr.sql "$s1 00:00:00" "$s1 04:00:00"
  runScript.sh -s -O AWR_${s2}_04h_08h.html -H getAwr.sql "$s1 04:00:00" "$s1 08:00:00"
  runScript.sh -s -O AWR_${s2}_08h_12h.html -H getAwr.sql "$s1 08:00:00" "$s1 12:00:00"
  runScript.sh -s -O AWR_${s2}_12h_16h.html -H getAwr.sql "$s1 12:00:00" "$s1 16:00:00"
  runScript.sh -s -O AWR_${s2}_16h_20h.html -H getAwr.sql "$s1 16:00:00" "$s1 20:00:00"
  runScript.sh -s -O AWR_${s2}_20h_24h.html -H getAwr.sql "$s1 20:00:00" "$s1 23:59:59"
  current_day=$next_day
done
