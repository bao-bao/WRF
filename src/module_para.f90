       module module_para
       
       integer, parameter :: nVars = 5

        character(len=8), parameter :: vNam(nVars) =  &
                                        (/"U", "V",  "T","MU", "QVAPOR"/)
        integer, parameter :: we = 55, sn = 55, vert = 21
        integer, parameter :: nLon(nVars) = (/we, we-1, we-1, we-1, we-1/)
        integer, parameter :: nLat(nVars) = (/sn-1, sn, sn-1, sn-1, sn-1/)
        integer, parameter :: nLev(nVars) = (/vert-1, vert-1, vert-1, 1, vert-1/)
        integer, parameter :: nTim(nVars) = (/1,  1,  1,  1,  1 /)

        integer, parameter :: nmax = 238356
        integer, parameter :: delta = 60
        end
