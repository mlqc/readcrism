temp1 = 0.0
temp2 = 0.0
temp3 = 0.0
ReadF, lun, header
FOR j=0,40 DO BEGIN
   ReadF, lun, temp1, temp2, temp3
   thisLat(j) = temp1
   thisLon(j) = temp2
   thisTemp(j) = temp3
ENDFOR
END
