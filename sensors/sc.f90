! Program SodarChecker - Test program for 'modos.f90' module.
!
! This program is part of the pbl_met library.
!
! Copyright 2018 by Servizi Territorio srl
!
! This is open-source code, covered by lGPL 3.0 license
!
program SodarChecker

	use modos
	
	implicit none
	
	! Locals
	integer			:: iRetCode
	type(ModosData)	:: tSodar
	integer			:: iSensorType
	integer			:: iNumChanges
	
	! Test 1: Read SDR data from SODAR-only station
	iRetCode = tSodar % load(10, "0616.sdr")
	print *, "Test 1: Get SDR data from SODAR-only station"
	print *, "Return code: ", iRetCode, "  (expected:0)"
	iSensorType = tSodar % getSensorType()
	print *, "Sensor type = ", iSensorType, "  (expected:", MDS_SODAR, ")"
	print *
	
	! Test 2: Count heights changes (a subset of configuration changes)
	print *, "Test 2: Count height changes"
	iRetCode = tSodar % getNumHeightChanges(iNumChanges)
	print *, "Return code: ", iRetCode, "  (expected:0)"
	print *, "Num.changes: ", iNumChanges, "  (expected:0)"
	print *

end program SodarChecker
