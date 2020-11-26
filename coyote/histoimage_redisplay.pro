PRO HistoImage_Redisplay, Image=image, _Extra=extra
IF N_Elements(image) EQ 0 THEN image = LoadData(7)
HistoImage, image, /NoLoadCT, _Extra=extra
END