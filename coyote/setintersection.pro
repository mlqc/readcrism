FUNCTION SetIntersection, a, b

  ; Find the intersection of the ranges.
  mina = Min(a, Max=maxa)
  minb = Min(b, Max=maxb)
  minab = mina > minb
  maxab = maxa < maxb

  ; If the set ranges don't intersect, then result = NULL.
  IF ((maxa LT minab) AND (minb GT maxab)) OR $
    ((maxb LT minab) AND (mina GT maxab)) THEN RETURN, -1

  r = Where((Histogram(a, Min=minab, Max=maxab) NE 0) AND  $
    (Histogram(b, Min=minab, Max=maxab) NE 0), count)

  IF count EQ 0 THEN RETURN, -1 ELSE RETURN, r + minab
END
