#!/bin/bash
# This Shell was initialized by Huizhen Yu in 07/2014 to run CNOP and FSV automatically
#
# 1. Definition
#-----------------------------------------------
#.. 1.1 define path

      # declare -r  work_dir="/vol6/home/pkuswans/usr/yuhz/CASES/CNOP_FSV_matsa/NEW/CNOP_FSV_domain1"
      # declare -r  wrfplus_dir="/vol6/home/pkuswans/usr/yuhz/WRF/WRF3.6.1/WRFPLUSV3"

       declare -r  work_dir="/home/baobao/Desktop/WRF_CNOPmatsa"
       declare -r  wrfplus_dir="/home/mode/WRFPLUSV3"

#.. 1.2 define the way to run
     declare -r  run="./wrf.exe"
#.. 1.3 define wrf experiment parameter
       max_dom=1
	   start_time=(2005 08 05 00 00)  # start time for year month day hour minute
           end_time=(2005 08 06 00 00)    # end time for year month day hour minute
	   interval_time=24              # wrf run time (hours)
	   interval_input=21600           # wrf boundary file interval time (second)
	   interval_output=360            # wrf output interval (minute)
	   wrf_dt=180                     # wrf run time step
	   wrf_dx=60000                  # horizontal resolution
	   wrf_dy=60000                  # horizontal resolution
	   e_we=55                        # domain grids on west-east
	   e_sn=55                        # domain  grids on south-north
	   e_vert=21                      # vertical levels
           p_top=5000                     # the top pressure in Pa
         # define the physics we choose in the forecast
	   mp_physics=0
           ra_lw_physics=0
           ra_sw_physics=0
	   sf_sfclay_physics=0
	   sf_surface_physics=1
	   bl_pbl_physics=98
	   cu_physics=0
         # define the verification area and delta value control the initial perturbation
           nmax=238356      # the dimesions and calculated by nLon*nLat*nLev in module_op.f
           i_st=20
           i_ed=28
           j_st=25
           j_ed=33
           k_st=1
           k_ed=20
           delta=60

#--------------------------------------------------------------------------------------------------
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# All definition were done
# Please don't modify the folllowing !!!!!!!!!!!!!!!!!!!!!!
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#-------------------------------------------------------------------------------------------------

# 2. Preapre to obtain CNOP and FSV
#----------------------------------------
#.. 2.1 produce the parameter
  cd ${work_dir}
    echo "creat parameter for verification area"
cat > verification << EOF
  ist= ${i_st}
  ied= ${i_ed}
  jst= ${j_st}
  jed= ${j_ed}
  kst= ${k_st}
  ked= ${k_ed}

EOF

  cd ${work_dir}/cnop/cnop/
    echo "creat parameter for domain design and delta value"
cat > module_para.f90 << EOF
       module module_para

       integer, parameter :: nVars = 5

        character(len=8), parameter :: vNam(nVars) =  &
                                        (/"U", "V",  "T","MU", "QVAPOR"/)
        integer, parameter :: we = ${e_we}, sn = ${e_sn}, vert = ${e_vert}
        integer, parameter :: nLon(nVars) = (/we, we-1, we-1, we-1, we-1/)
        integer, parameter :: nLat(nVars) = (/sn-1, sn, sn-1, sn-1, sn-1/)
        integer, parameter :: nLev(nVars) = (/vert-1, vert-1, vert-1, 1, vert-1/)
        integer, parameter :: nTim(nVars) = (/1,  1,  1,  1,  1 /)

        integer, parameter :: nmax = ${nmax}
        integer, parameter :: delta = ${delta}
        end
EOF
    cp -r module_para.f90 ${work_dir}/lsv/fsv/.

#.. 2.2 produce the csh files to combine WRF and SPG2
  cd ${work_dir}/cnop/cnop/
#pwd
  rm run_opb*.csh
   echo "creat csh files for CNOP"
work_dir_cd='$work_dir'
run_cd='$run'
cat > run_opb_f.csh << EOF
#!/bin/csh
#
#        Huizhen Yu and Hongli Wang NCAR/MMM 2013/10
#
# need to change ###
setenv work_dir ${work_dir}/cnop/sop/
set run="${run}"

# end of modification ###
#
echo "1d to tl_3d"
cd $work_dir_cd
cp -r ../cnop/fort.1001 .
ncl opb_pre_1.ncl >! opb_pre_1.log

cd $work_dir_cd/working_nl
echo "run wrf_nl"
$run_cd >! nl.log
wait
sleep 1
ncl wrfout.ncl >! wrfout.log

echo "tl_out to ad_in"
cd $work_dir_cd
ncl opb_mid_1.ncl >! opb_mid_1.log

echo "ad_in_3d to 1d"
cd $work_dir_cd
ncl opb_fin_1.ncl >! opb_fin_1.log

cd $work_dir_cd
cp -r fort.1002 ../cnop/

EOF

cd ${work_dir}/cnop/cnop/
#pwd
cat > run_opb.csh << EOF
#!/bin/csh
#
#        Huizhen Yu and Hongli Wang NCAR/MMM 2013/10
#
# need to change ###
setenv  work_dir ${work_dir}/cnop/sop/
set run="${run}"

# end of modification ###
#
echo "1d to tl_3d"
cd $work_dir_cd
cp -r ../cnop/fort.1001 .
ncl opb_pre_1.ncl >! opb_pre_1.log

cd $work_dir_cd/working_nl
echo "run wrf_nl"
${run_cd} >! nl.log
wait
sleep 1
ncl wrfout.ncl >! wrfout.log

echo "tl_out to ad_in"
cd $work_dir_cd
ncl opb_mid.ncl >! opb_mid.log

cd $work_dir_cd/working_ad
echo "run wrf_ad"
${run_cd} >! ad.log
wait
sleep 1
echo "ad_out_3d to 1d"
cd $work_dir_cd
ncl opb_fin.ncl >! opb_fin.log

cd $work_dir_cd
cp -r fort.1002 ../cnop/

EOF

cd ${work_dir}/lsv/fsv/
#pwd
 rm run_opb*.csh
 echo "creat csh files for FSV"

cat > run_opb.csh << EOF
#!/bin/csh
#
#        Hongli Wang and Huizhen Yu NCAR/MMM 2013/10
#
# need to change  ###
setenv work_dir ${work_dir}/lsv/sop
set run="${run}"

# end of modification ###
#
echo "1d to tl_3d"
cd $work_dir_cd
cp -r ../fsv/fort.1001 .
ncl opb_pre.ncl >! opb_pre.log

cd $work_dir_cd/working_tl
echo "run wrf_tl"
${run_cd} >! tl.log
wait
sleep 1

echo "tl_out to ad_in"
cd $work_dir_cd
ncl opb_mid.ncl >! opb_mid.log

cd $work_dir_cd/working_ad
echo "run wrf_ad"
${run_cd} >! ad.log
wait
sleep 1

echo "ad_out_3d to 1d"
cd $work_dir_cd
ncl opb_fin.ncl >! opb_fin.log

cd $work_dir_cd
cp -r fort.1002 ../fsv/

EOF


cat > run_opb_f.csh << EOF
#!/bin/csh
#
#        Hongli Wang and Huizhen Yu NCAR/MMM 2013/10
#
# need to change ###
setenv work_dir ${work_dir}/lsv/sop/
set run="${run}"
# end of modification ###
#
echo "1d to tl_3d"
cd $work_dir_cd
cp -r ../fsv/fort.1001 .
ncl opb_pre.ncl >! opb_pre.log

cd $work_dir_cd/working_tl
echo "run wrf_tl"
${run_cd} >! tl.log
wait
sleep 1

echo "tl_out to ad_in"
cd $work_dir_cd
ncl opb_mid_1.ncl >! opb_mid_1.log

echo "ad_in_3d to 1d"
cd $work_dir_cd
ncl opb_fin_1.ncl >! opb_fin_1.log

cd $work_dir_cd
cp -r fort.1002 ../fsv/

EOF

cd ${work_dir}/cnop/cnop/
#pwd
chmod u+x run_opb.csh
chmod u+x run_opb_f.csh
cd ${work_dir}/lsv/fsv/
#pwd
chmod u+x run_opb.csh
chmod u+x run_opb_f.csh


#.. 2.3 produce WRF namelist for nonlinear model and TL and AD models(just the basic namelist, modified it when jobs needs)
   cd ${work_dir}
    echo "creat namelist for WRF models"

	rm -f namelist.input_*
cat > namelist.input_nl << EOF
&time_control
run_days = 0,
run_hours = ${interval_time} ,
run_minutes = 0,
run_seconds = 0,
start_year = ${start_time[0]},
start_month = ${start_time[1]},
start_day = ${start_time[2]},
start_hour = ${start_time[3]},
start_minute = ${start_time[4]},
start_second = 00,
end_year = ${end_time[0]},
end_month = ${end_time[1]},
end_day = ${end_time[2]},
end_hour = ${end_time[3]},
end_minute = ${end_time[4]},
end_second = 00,
interval_seconds = ${interval_input},
input_from_file = .true.,
history_interval = ${interval_output},
frames_per_outfile = 1,
restart = .false.,
restart_interval = 144000,
io_form_history = 2,
io_form_restart = 2,
io_form_input = 2,
io_form_boundary = 2,
diag_print = 2,
debug_level = 0,
/

&domains
time_step = ${wrf_dt},
time_step_fract_num = 0,
time_step_fract_den = 1,
max_dom = ${max_dom},
max_dz=10000,
e_we = ${e_we}
e_sn = ${e_sn}
e_vert = ${e_vert},
num_metgrid_levels = 27,
grid_id = 1,
parent_id = 1,
parent_grid_ratio = 1,
parent_time_step_ratio = 1,
i_parent_start = 1,
j_parent_start = 1,
dx = ${wrf_dx}
dy = ${wrf_dy}
p_top_requested = ${p_top},
feedback = 1,
smooth_option = 0,

/

&physics
mp_physics = ${mp_physics}
ra_lw_physics = ${ra_lw_physics}
ra_sw_physics = ${ra_sw_physics}
radt = 10,
sf_sfclay_physics = ${sf_sfclay_physics}
sf_surface_physics = ${sf_surface_physics}
bl_pbl_physics = ${bl_pbl_physics}
bldt = 0,
cu_physics = ${cu_physics}
cudt = 5,
surface_input_source = 1,
num_soil_layers = 5,
sf_ocean_physics = 1,
/
&fdda
/
&dynamics
dyn_opt=2,
w_damping = 1,
diff_opt = 1,
km_opt = 4,
base_temp = 290.,
damp_opt = 0,
zdamp = 5000.,
dampcoef = 0.2,
/
&bdy_control
spec_bdy_width = 5,
spec_zone = 1,
relax_zone = 4,
specified = .true.,
nested = .false.,
/
&grib2
/
&namelist_quilt
nio_tasks_per_group = 0,
nio_groups = 1,
/

EOF

cat > namelist.input_tl << EOF
&noah_mp
/
&time_control
run_days = 0,
run_hours = ${interval_time} ,
run_minutes = 0,
run_seconds = 0,
start_year = ${start_time[0]},
start_month = ${start_time[1]},
start_day = ${start_time[2]},
start_hour = ${start_time[3]},
start_minute = ${start_time[4]},
start_second = 00,
end_year = ${end_time[0]},
end_month = ${end_time[1]},
end_day = ${end_time[2]},
end_hour = ${end_time[3]},
end_minute = ${end_time[4]},
end_second = 00,
interval_seconds = ${interval_input},
input_from_file = true,
write_input=false,
auxhist6_outname="./auxhist6_d<domain>_<date>",
 auxhist6_interval=5,
 auxhist6_begin_h=0,
 auxhist6_end_h=12,
 io_form_auxhist6=2,
 frames_per_auxhist6=1,
 frames_per_outfile=1,
 debug_level=0,
 inputout_interval=1,
 inputout_begin_h=0,
 inputout_end_h=24,
 io_form_auxhist8                    = 2,
 auxhist8_interval_h                 = 1,
 frames_per_auxhist8                 = 1,
 iofields_filename                   = "plus.io_config",
 ignore_iofields_warning             = .true.,
/

&domains
time_step = ${wrf_dt},
e_we = ${e_we}
e_sn = ${e_sn}
e_vert = ${e_vert},
num_metgrid_levels = 27,
i_parent_start = 1,
j_parent_start = 1,
dx = ${wrf_dx}
dy = ${wrf_dy}
p_top_requested = ${p_top},
feedback = 1,
smooth_option = 0,
nproc_x=0,
/

&physics
mp_physics = ${mp_physics}
ra_lw_physics = ${ra_lw_physics}
ra_sw_physics = ${ra_sw_physics}
radt = 10,
sf_sfclay_physics = ${sf_sfclay_physics}
sf_surface_physics = ${sf_surface_physics}
bl_pbl_physics = ${bl_pbl_physics}
bldt = 0,
cu_physics = ${cu_physics}
cudt = 5,
num_soil_layers = 5,
/
&fdda
/
&dynamics
dyn_opt=202,
w_damping = 1,
diff_opt = 1,
km_opt = 4,
base_temp = 290.,
damp_opt = 0,
zdamp = 5000.,
dampcoef = 0.2,
/
&bdy_control
spec_bdy_width = 5,
spec_zone = 1,
relax_zone = 4,
specified = .true.,
nested = .false.,
/
&grib2
/
&fire
/
&perturbation
trajectory_io=.true.,
tl_standalone=.true.,
/
&diags
/
&namelist_quilt
/
EOF

cat > namelist.input_ad << EOF
&time_control
run_days = 0,
run_hours = ${interval_time} ,
run_minutes = 0,
run_seconds = 0,
start_year = ${start_time[0]},
start_month = ${start_time[1]},
start_day = ${start_time[2]},
start_hour = ${start_time[3]},
start_minute = ${start_time[4]},
start_second = 00,
end_year = ${end_time[0]},
end_month = ${end_time[1]},
end_day = ${end_time[2]},
end_hour = ${end_time[3]},
end_minute = ${end_time[4]},
end_second = 00,
interval_seconds = ${interval_input},
input_from_file = .true.,
frames_per_outfile = 1,
debug_level = 0,
write_input=false,
io_form_auxhist7=2,
auxinput6_inname="./auxhist6_d<domain>_<date>",
io_form_auxinput6=2,
frames_per_auxinput6=1,
debug_level=0,
iofields_filename="plus.io_config",
ignore_iofields_warning=true,
/

&domains
time_step = ${wrf_dt},
time_step_fract_num = 0,
time_step_fract_den = 1,
max_dom = ${max_dom},
max_dz=10000,
e_we = ${e_we}
e_sn = ${e_sn}
e_vert = ${e_vert},
num_metgrid_levels = 27,
grid_id = 1,
parent_id = 1,
parent_grid_ratio = 1,
parent_time_step_ratio = 1,
i_parent_start = 1,
j_parent_start = 1,
dx = ${wrf_dx}
dy = ${wrf_dy}
p_top_requested = ${p_top},
feedback = 1,
smooth_option = 0,

/

&physics
mp_physics = ${mp_physics}
ra_lw_physics = ${ra_lw_physics}
ra_sw_physics = ${ra_sw_physics}
radt = 10,
sf_sfclay_physics = ${sf_sfclay_physics}
sf_surface_physics = ${sf_surface_physics}
bl_pbl_physics = ${bl_pbl_physics}
bldt = 0,
cu_physics = ${cu_physics}
cudt = 5,
surface_input_source = 1,
num_soil_layers = 5,
sf_ocean_physics = 1,
/
&fdda
/
&dynamics
dyn_opt=302,
w_damping = 1,
diff_opt = 1,
km_opt = 4,
base_temp = 290.,
damp_opt = 0,
zdamp = 5000.,
dampcoef = 0.2,
/
&bdy_control
spec_bdy_width = 5,
spec_zone = 1,
relax_zone = 4,
specified = .true.,
nested = .false.,
/
&grib2
/
&namelist_quilt
nio_tasks_per_group = 0,
nio_groups = 1,
/

EOF

#..2.4 linking to the wrfplus code
echo "prepare for wrfplus linking"
ln -sf $wrfplus_dir/run/CAM_ABS_DATA $work_dir/initial/working/CAM_ABS_DATA
ln -sf $wrfplus_dir/run/CAM_AEROPT_DATA $work_dir/initial/working/CAM_AEROPT_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/initial/working/ETAMPNEW_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/initial/working/ETAMPNEW_DATA_DBL
ln -sf $wrfplus_dir/run/GENPARM.TBL $work_dir/initial/working/GENPARM.TBL
ln -sf $wrfplus_dir/run/gribmap.txt $work_dir/initial/working/gribmap.txt
ln -sf $wrfplus_dir/run/LANDUSE.TBL $work_dir/initial/working/LANDUSE.TBL
ln -sf $wrfplus_dir/run/MPTABLE.TBL $work_dir/initial/working/MPTABLE.TBL
ln -sf $wrfplus_dir/run/RRTM_DATA_DBL $work_dir/initial/working/RRTM_DATA
ln -sf $wrfplus_dir/run/RRTMG_LW_DATA_DBL $work_dir/initial/working/RRTMG_LW_DATA
ln -sf $wrfplus_dir/run/SOILPARM.TBL $work_dir/initial/working/SOILPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM.TBL $work_dir/initial/working/URBPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM_UZE.TBL $work_dir/initial/working/URBPARM_UZE.TBL
ln -sf $wrfplus_dir/run/VEGPARM.TBL $work_dir/initial/working/VEGPARM.TBL
ln -sf $wrfplus_dir/main/wrf.exe $work_dir/initial/working/wrf.exe
#
#
ln -sf $wrfplus_dir/run/CAM_ABS_DATA $work_dir/cnop/sop/working_nl/CAM_ABS_DATA
ln -sf $wrfplus_dir/run/CAM_AEROPT_DATA $work_dir/cnop/sop/working_nl/CAM_AEROPT_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/cnop/sop/working_nl/ETAMPNEW_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/cnop/sop/working_nl/ETAMPNEW_DATA_DBL
ln -sf $wrfplus_dir/run/GENPARM.TBL $work_dir/cnop/sop/working_nl/GENPARM.TBL
ln -sf $wrfplus_dir/run/gribmap.txt $work_dir/cnop/sop/working_nl/gribmap.txt
ln -sf $wrfplus_dir/run/LANDUSE.TBL $work_dir/cnop/sop/working_nl/LANDUSE.TBL
ln -sf $wrfplus_dir/run/MPTABLE.TBL $work_dir/cnop/sop/working_nl/MPTABLE.TBL
ln -sf $wrfplus_dir/run/RRTM_DATA_DBL $work_dir/cnop/sop/working_nl/RRTM_DATA
ln -sf $wrfplus_dir/run/RRTMG_LW_DATA_DBL $work_dir/cnop/sop/working_nl/RRTMG_LW_DATA
ln -sf $wrfplus_dir/run/SOILPARM.TBL $work_dir/cnop/sop/working_nl/SOILPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM.TBL $work_dir/cnop/sop/working_nl/URBPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM_UZE.TBL $work_dir/cnop/sop/working_nl/URBPARM_UZE.TBL
ln -sf $wrfplus_dir/run/VEGPARM.TBL $work_dir/cnop/sop/working_nl/VEGPARM.TBL
ln -sf $wrfplus_dir/main/wrf.exe $work_dir/cnop/sop/working_nl/wrf.exe
#
ln -sf $wrfplus_dir/run/CAM_ABS_DATA $work_dir/cnop/sop/working_ad/CAM_ABS_DATA
ln -sf $wrfplus_dir/run/CAM_AEROPT_DATA $work_dir/cnop/sop/working_ad/CAM_AEROPT_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/cnop/sop/working_ad/ETAMPNEW_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/cnop/sop/working_ad/ETAMPNEW_DATA_DBL
ln -sf $wrfplus_dir/run/GENPARM.TBL $work_dir/cnop/sop/working_ad/GENPARM.TBL
ln -sf $wrfplus_dir/run/gribmap.txt $work_dir/cnop/sop/working_ad/gribmap.txt
ln -sf $wrfplus_dir/run/LANDUSE.TBL $work_dir/cnop/sop/working_ad/LANDUSE.TBL
ln -sf $wrfplus_dir/run/MPTABLE.TBL $work_dir/cnop/sop/working_ad/MPTABLE.TBL
ln -sf $wrfplus_dir/run/RRTM_DATA_DBL $work_dir/cnop/sop/working_ad/RRTM_DATA
ln -sf $wrfplus_dir/run/RRTMG_LW_DATA_DBL $work_dir/cnop/sop/working_ad/RRTMG_LW_DATA
ln -sf $wrfplus_dir/run/SOILPARM.TBL $work_dir/cnop/sop/working_ad/SOILPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM.TBL $work_dir/cnop/sop/working_ad/URBPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM_UZE.TBL $work_dir/cnop/sop/working_ad/URBPARM_UZE.TBL
ln -sf $wrfplus_dir/run/VEGPARM.TBL $work_dir/cnop/sop/working_ad/VEGPARM.TBL
ln -sf $wrfplus_dir/main/wrf.exe $work_dir/cnop/sop/working_ad/wrf.exe
#
ln -sf $wrfplus_dir/run/CAM_ABS_DATA $work_dir/lsv/sop/working_tl/CAM_ABS_DATA
ln -sf $wrfplus_dir/run/CAM_AEROPT_DATA $work_dir/lsv/sop/working_tl/CAM_AEROPT_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/lsv/sop/working_tl/ETAMPNEW_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/lsv/sop/working_tl/ETAMPNEW_DATA_DBL
ln -sf $wrfplus_dir/run/GENPARM.TBL $work_dir/lsv/sop/working_tl/GENPARM.TBL
ln -sf $wrfplus_dir/run/gribmap.txt $work_dir/lsv/sop/working_tl/gribmap.txt
ln -sf $wrfplus_dir/run/LANDUSE.TBL $work_dir/lsv/sop/working_tl/LANDUSE.TBL
ln -sf $wrfplus_dir/run/MPTABLE.TBL $work_dir/lsv/sop/working_tl/MPTABLE.TBL
ln -sf $wrfplus_dir/run/RRTM_DATA_DBL $work_dir/lsv/sop/working_tl/RRTM_DATA
ln -sf $wrfplus_dir/run/RRTMG_LW_DATA_DBL $work_dir/lsv/sop/working_tl/RRTMG_LW_DATA
ln -sf $wrfplus_dir/run/SOILPARM.TBL $work_dir/lsv/sop/working_tl/SOILPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM.TBL $work_dir/lsv/sop/working_tl/URBPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM_UZE.TBL $work_dir/lsv/sop/working_tl/URBPARM_UZE.TBL
ln -sf $wrfplus_dir/run/VEGPARM.TBL $work_dir/lsv/sop/working_tl/VEGPARM.TBL
ln -sf $wrfplus_dir/main/wrf.exe $work_dir/lsv/sop/working_tl/wrf.exe
#
ln -sf $wrfplus_dir/run/CAM_ABS_DATA $work_dir/lsv/sop/working_ad/CAM_ABS_DATA
ln -sf $wrfplus_dir/run/CAM_AEROPT_DATA $work_dir/lsv/sop/working_ad/CAM_AEROPT_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/lsv/sop/working_ad/ETAMPNEW_DATA
ln -sf $wrfplus_dir/run/ETAMPNEW_DATA_DBL $work_dir/lsv/sop/working_ad/ETAMPNEW_DATA_DBL
ln -sf $wrfplus_dir/run/GENPARM.TBL $work_dir/lsv/sop/working_ad/GENPARM.TBL
ln -sf $wrfplus_dir/run/gribmap.txt $work_dir/lsv/sop/working_ad/gribmap.txt
ln -sf $wrfplus_dir/run/LANDUSE.TBL $work_dir/lsv/sop/working_ad/LANDUSE.TBL
ln -sf $wrfplus_dir/run/MPTABLE.TBL $work_dir/lsv/sop/working_ad/MPTABLE.TBL
ln -sf $wrfplus_dir/run/RRTM_DATA_DBL $work_dir/lsv/sop/working_ad/RRTM_DATA
ln -sf $wrfplus_dir/run/RRTMG_LW_DATA_DBL $work_dir/lsv/sop/working_ad/RRTMG_LW_DATA
ln -sf $wrfplus_dir/run/SOILPARM.TBL $work_dir/lsv/sop/working_ad/SOILPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM.TBL $work_dir/lsv/sop/working_ad/URBPARM.TBL
ln -sf $wrfplus_dir/run/URBPARM_UZE.TBL $work_dir/lsv/sop/working_ad/URBPARM_UZE.TBL
ln -sf $wrfplus_dir/run/VEGPARM.TBL $work_dir/lsv/sop/working_ad/VEGPARM.TBL
ln -sf $wrfplus_dir/main/wrf.exe $work_dir/lsv/sop/working_ad/wrf.exe
#

#.. 2.5 some pre-post before calculating CNOP and FSV
 cd ${work_dir}/initial/
 echo "initial control run"
cp -r ../wrfinput_d01 .
cp -r ../wrfbdy_d01 .
ln -sf $work_dir/namelist.input_nl $work_dir/initial/working/namelist.input
cd $work_dir/initial/working/
rm wrfout_d0*
${run} >! nl.log

echo "initial perturbation"
cd $work_dir/initial/working/
ln -sf wrfout_d01_${start_time[0]}-${start_time[1]}-${start_time[2]}_${start_time[3]}:00:00 wrfout1
ln -sf wrfout_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 wrfout2

cd $work_dir/initial/
rm fort.1000*
ncl pert.ncl
ncl ran.ncl

##
echo "prepare for FSV"
echo "working_tl"
cd $work_dir/lsv/
cp -r ../wrfinput_d01 .
cp -r ../wrfbdy_d01 .
ln -sf $work_dir/namelist.input_tl $work_dir/lsv/sop/working_tl/namelist.input
cd $work_dir/lsv/sop/working_tl/
rm auxhist8_d01*
cd $work_dir/lsv/sop/working_tl/
ln -sf auxhist8_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 auxhist_d01
${run} >! tl.log

cd $work_dir/lsv/sop/working_tl/
ln -sf auxhist8_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 auxhist_d01

echo "working_ad"
ln -sf $work_dir/namelist.input_ad $work_dir/lsv/sop/working_ad/namelist.input
cp -r $work_dir/initial/working/wrfout_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 $work_dir/lsv/sop/working_ad/final_sens_d01

cd $work_dir/lsv/sop/working_ad/
rm gradient_wrfplus_d01_*
${run} >! ad.log
ln -sf gradient_wrfplus_d01_${start_time[0]}-${start_time[1]}-${start_time[2]}_${start_time[3]}:00:00 gradient_wrfplus_d01

##
echo "prepare for CNOP"
echo "working_nl"
cd $work_dir/cnop/
cp -r ../wrfinput_d01 .
cp -r ../wrfbdy_d01 .
cd $work_dir/cnop/sop/
cp -r ../wrfinput_d01 .
cp -r ../wrfinput_d01 wrfinput_new
cp -r ../wrfbdy_d01 .


ln -sf $work_dir/namelist.input_nl $work_dir/cnop/sop/working_nl/namelist.input
cd $work_dir/cnop/sop/working_nl/
rm wrfout_d01_*
${run} >! nl.log
ln -sf $work_dir/initial/working/wrfout_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 $work_dir/cnop/sop/working_nl/wrfout1
ln -sf wrfout_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 $work_dir/cnop/sop/working_nl/wrfout2
cp -r $work_dir/lsv/sop/working_tl/auxhist8_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 $work_dir/cnop/sop/working_nl/auxhist_d01

echo "working_ad"
ln -sf $work_dir/namelist.input_ad $work_dir/cnop/sop/working_ad/namelist.input
cp -r $work_dir/initial/working/wrfout_d01_${end_time[0]}-${end_time[1]}-${end_time[2]}_${end_time[3]}:00:00 $work_dir/cnop/sop/working_ad/final_sens_d01
cd $work_dir/cnop/sop/working_ad/
rm gradient_wrfplus_d01_*
${run} >! ad.log
ln -sf gradient_wrfplus_d01_${start_time[0]}-${start_time[1]}-${start_time[2]}_${start_time[3]}:00:00 gradient_wrfplus_d01

#.. 3 Compile and run the module
 cd ${work_dir}/cnop/cnop
 ln -sf ../../initial/fort.1000_1 fort.1000
 cd ${work_dir}/lsv/fsv
 ln -sf ../../initial/fort.1000_1 fort.1000

 echo "Successfully preparation"
 echo "go to the folder to compile and run the module to calculate CNOP and FSV"


exit





