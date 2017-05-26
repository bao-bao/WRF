load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
       ;
       ; Huizhen Yu and Hongli Wang and Jianyu Liu NCAR/MMM 2013/10
       ;
begin


; adding the wrinput_d01 and reading ZNW
  wrfinput = addfile("wrfinput_d01.nc","r")

; making the delta of eta, and get the average of eta
  if ( .not. isvar("vEta") ) then
   vEta1=wrfinput->$"ZNW"$
   size = dimsizes(vEta1)
   vEta = reshape(vEta1,(/size(1)/))
;  print("vEta " + vEta)
  end if
  nEta = dimsizes(vEta) - 1


  if ( .not. isvar("vEta_delta") ) then
     vEta_delta = vEta
  end if

  do i = 0, nEta-1
     vEta_delta(i) = vEta(i)-vEta(i+1)
  end do
  tot_eta_delta=sum(vEta_delta(0:nEta-1))
; making the delta of eta, and get the average of eta

; adding the wrinput_d01 and reading mub
  wrfout1 = addfile("wrfout1.nc","r")
  u1  =wrfout1->$"U"$
  v1  =wrfout1->$"V"$
  t1  =wrfout1->$"T"$
  mu1 =wrfout1->$"MU"$
  qv1 =wrfout1->$"QVAPOR"$


  wrfout2 = addfile("wrfout2.nc","r")
  u2  =wrfout2->$"U"$
  v2  =wrfout2->$"V"$
  t2  =wrfout2->$"T"$
  mu2 =wrfout2->$"MU"$
  qv2 =wrfout2->$"QVAPOR"$


; adding the wrinput_d01 and reading mub
  

  if ( .not. isvar("vNam") ) then
    vNam=(/"A_U", "A_V", "A_T", "A_MU", "A_QVAPOR"/)
  end if

  if ( .not. isvar("ofil")) then
    ofil="auxhist_d01"
  end if

  print("Output file : " + ofil )

  suffix = str_get_cols(ofil, -3, -1)
  if ( suffix .ne. ".nc" ) then
    suffix = ".nc"
  else
    suffix = ""
  end if

  f_auxhist = addfile(ofil+suffix,"rw")
  if ( ismissing(f_auxhist) ) then
    print("Failed open file : " + ofil)
    status_exit(-1)
  end if

  nVars = dimsizes(vNam) - 1
  skipped = 0

  do i=0, nVars 

    A_VAR=vNam(i)
    G_VAR = "G"+str_get_cols(A_VAR, 1, -1)

    print("Processing " + A_VAR)

    if ( .not. isfilevar(f_auxhist, G_VAR) ) then
      print("Warning : " + G_VAR + " Not available in file " + ifil + ", skipped")
      skipped = skipped + 1
      continue
    end if

    vc = f_auxhist->$G_VAR$

    vc = 0.

    dsizes = dimsizes(vc)
    if ( G_VAR .eq. "G_T" ) then
    do k = 0, nEta-1
        vc(0,k,:,:) = t2(0,k,:,:)-t1(0,k,:,:)
       ;vc(0,k,j,ii) = 0.1
    end do
    end if
    if ( G_VAR .eq. "G_U" ) then
    do k = 0, nEta-1
        vc(0,k,:,:) = u2(0,k,:,:)-u1(0,k,:,:)
    end do
    end if
     if ( G_VAR .eq. "G_V" ) then
    do k = 0, nEta-1
        vc(0,k,:,:) = v2(0,k,:,:)-v1(0,k,:,:)
    end do
    end if
    if ( G_VAR .eq. "G_QVAPOR" ) then
	    do k = 1, nEta-1
	       vc(0,k,:,:) = qv2(0,k,:,:) - qv1(0,k,:,:)
	    end do
    end if
 
    if ( G_VAR .eq. "G_MU" ) then
       vc(0,:,:) = mu2(0,:,:) - mu1(0,:,:)
    end if
    
    ;f_final_sens->$A_VAR$ = doubletofloat(vc)
    f_auxhist->$G_VAR$ = vc
    delete(vc)
    delete(dsizes)
  end do

  if ( skipped .gt. 0 ) then
    print("Failed to process all variables")
  else
    print("Completed successfully")
  end if

end
