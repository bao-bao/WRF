load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
       ;
       ; Hongli Wang and Huizhen Yu and Jianyu Liu NCAR/MMM 2013/10
       ;
begin

;  t_scale=0.
;  mu_scale=0.
  q_scale=0.
;  t_scale=9.8/3.
  mu_scale=1./300.

;  t_scale  =sqrt(1005.7/270)
  mu_scale =sqrt(287.04*270)/100000.

; adding the wrinput_d01 and reading mub
  wrfinput = addfile("wrfinput_d01.nc","r")
  mub=wrfinput->$"MUB"$
; adding the wrinput_d01 and reading mub

; making the delta of eta, and get the average of eta
  if ( .not. isvar("vEta") ) then
   vEta1=wrfinput->$"ZNW"$
   size = dimsizes(vEta1)
   vEta = reshape(vEta1,(/size(1)/))
  print("vEta " + vEta)
  end if
  nEta = dimsizes(vEta) - 1
 
;  t_scale = vEta
  t_scale  =sqrt(1005.7/270)*vEta^0.286
 
print("t_scale = " + t_scale)

  if ( .not. isvar("vEta_delta") ) then
     vEta_delta = vEta
  end if

  do i = 0, nEta-1
     vEta_delta(i) = vEta(i)-vEta(i+1)
  end do
  tot_eta_delta=sum(vEta_delta(0:nEta-1))
; making the delta of eta, and get the average of eta

;read initial statu in wrfinput_d01
  u  =wrfinput->$"U"$
; print("size of u = " + dimsizes(u))
  v  =wrfinput->$"V"$
  t  =wrfinput->$"T"$
  mu =wrfinput->$"MU"$
  qv =wrfinput->$"QVAPOR"$


  if ( .not. isvar("vNam") ) then
    vNam=(/"A_U", "A_V", "A_T", "A_MU", "A_QVAPOR"/)
  end if
    VARIABLE=(/"U","V","T","MU","QVAPOR"/)


  if ( .not. isvar("ifil")) then
    ifil="fort.1001"
  end if
 
  ofil="wrfinput_new.nc"

  fils = (/ifil, ofil/)
  ff = addfile("auxhist_d01","r")

  f_final_sens = addfile(ofil,"rw")
  if ( ismissing(f_final_sens) ) then
    print("Failed open file : " + ofil)
    status_exit(-1)
  end if


  print("Input  file : " + ifil )
  print("Output file : " + ofil )

  nVars = dimsizes(vNam) - 1
  skipped = 0

  do i=0, nVars 

    A_VAR=vNam(i)
    G_VAR = "G"+str_get_cols(A_VAR, 1, -1)
    VAR = VARIABLE(i)

    print("Processing " + A_VAR)
    print("Processing " + VAR)

    vv = ff->$G_VAR$
    dsizes = dimsizes(vv)
;    print("dsize= " + dsizes)    

     vc = ff->$G_VAR$
;    vc = fbinrecread(ifil, i, dsizes, "double")
    vb = fbinrecread(ifil, i, dsizes, "double")
     vc = 0.0
;    print("dsize of vb= " + dimsizes(vb))

    if ( G_VAR .eq. "G_T" ) then
;    if( t_scale .eq. 0.0 ) then
;            do k = 0, nEta-1
;                vc(0,k,:,:) = t(0,k,:,:) + vb(0,k,:,:) * t_scale
;            end do
;       else
     do k = 0, nEta-1
             vc(0,k,:,:) = t(0,k,:,:) + vb(0,k,:,:) / (t_scale(k)) ;/ mub(0,:,:) / vEta_delta(k)
             ;vc(0,k,j,ii) = 0.1
     end do
;    end if
    end if
    if ( G_VAR .eq. "G_U" ) then
       mub_u = new((/dsizes(2),dsizes(3)/),"double")
       mub_u(:,0:dsizes(3)-2) = mub(0,:,:)
       mub_u(:,dsizes(3)-1) = 2* mub_u(:,dsizes(3)-2) -  mub_u(:,dsizes(3)-3)
    do k = 0, nEta-1
             vc(0,k,:,:) = u(0,k,:,:) + vb(0,k,:,:) ;/  mub_u(:,:) / vEta_delta(k)
    end do
    end if
     if ( G_VAR .eq. "G_V" ) then
      mub_v = new((/dsizes(2),dsizes(3)/),"double")
      mub_v(0:dsizes(2)-2,:) = mub(0,:,:)
      mub_v(dsizes(2)-1,:) = 2* mub_v(dsizes(2)-2,:) -  mub_v(dsizes(2)-3,:)
    do k = 0, nEta-1
             vc(0,k,:,:) = v(0,k,:,:) + vb(0,k,:,:) ;/  mub_v(:,:) / vEta_delta(k)
    end do
    end if
    if ( G_VAR .eq. "G_QVAPOR" ) then
       if( q_scale .eq. 0.0 ) then
            do k = 0, nEta-1
                 vc(0,k,:,:) = qv(0,k,:,:) + vb(0,k,:,:) * q_scale
            end do
       else
	    do k = 0, nEta-1
	          vc(0,k,:,:) = qv(0,k,:,:) + vb(0,k,:,:) / (q_scale); /mub(0,:,:) / vEta_delta(k)
	    end do
       end if
    end if
 
    if ( G_VAR .eq. "G_MU" ) then
        if( mu_scale .eq. 0.0 ) then
            do k = 0, nEta-1
             vc(0,:,:) = mu(0,:,:) + vb(0,:,:) * mu_scale
            end do
       else
             vc(0,:,:) =  mu(0,:,:) + vb(0,:,:) / (mu_scale) ; / mub(0,:,:) / tot_eta_delta
     end if
    end if

;    print("size of vc= " + dimsizes(vc))    
;    fbinrecwrite (ofil, -1, vc)
;    asciiwrite("mub_u.txt",mub_u)
    
    ;f_final_sens->$A_VAR$ = doubletofloat(vc)
    ;f_final_sens->$A_VAR$ = vc
    f_final_sens->$VAR$ = doubletofloat(vc)    

    delete(vc)
    delete(vb)
    delete(vv)
    delete(dsizes)
  end do

  if ( skipped .gt. 0 ) then
    print("Failed to process all variables")
  else
    print("Completed successfully")
  end if

end
