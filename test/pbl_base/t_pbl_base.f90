! The 'pbl_base' sub-library, part of 'pbl_met', contains functions used by other
! sub-libraries and, occasionally, end-user code. The large part of it is tested
! indirectly, by calling parts from other sub-libraries and their test programs.
!
! The present test program is aimed at testing a subset of the functions and
! data types of pbl_base, which are easier to check in a systematic way.
!
! This program is part of the pbl_met project.
!
! pbl_met is an open-source library aimed at meteorological data processing
! and meteorological processor crafting.
!
! Copyright 2018 by Servizi Territorio srl
!
program t_pbl_base

	use pbl_met
	
	implicit none

	! Locals
	
	! Perform tests
	call tstIniFile()
	call tstIncompleteGamma()

contains

	subroutine tstIniFile()
	
		! Routine arguments
		! -none-
		
		! Locals
		type(IniFile)		:: tIniFile
		integer				:: iRetCode
		character(len=256)	:: sValue
		integer				:: iValue
		real				:: rValue
		real(8)				:: rValue8
		
		! Test 1: Load test configuration, then dump it
		print *, 'Test 1 - Check INI read and decode on an existing file'
		iRetCode = tIniFile % read(10, "test.ini")
		if(iRetCode /= 0) then
			print *, 'Test 1 failed: please identify and correct the malfunction'
			stop
		end if
		iRetCode = tIniFile % dump()
		print *
		
		! Test 2: get string value from INI
		print *, 'Test 2: Get string values from INI'
		print *
		print *, 'Case 1: Get existent string, without default'
		iRetCode = tIniFile % getString("Mysterious", "Boh", sValue)
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: SunChi)'
		print *
		print *, 'Case 2: Get existent string, with default'
		iRetCode = tIniFile % getString("Mysterious", "Boh", sValue, 'Artificial_default')
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: SunChi)'
		print *
		print *, 'Case 3: Try loading non-existent string, no default'
		iRetCode = tIniFile % getString("Nonsensical", "Wrong", sValue)
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: empty string)'
		print *
		print *, 'Case 4: Try loading non-existent string, with default'
		iRetCode = tIniFile % getString("Nonsensical", "Wrong", sValue, "--missing--")
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: --missing--)'
		print *
		print *, 'Case 5: Try loading existent string, with empty section'
		iRetCode = tIniFile % getString("", "here", sValue)
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: Here I am, amnyway)'
		print *
		print *, 'Case 6: Try loading existent string, with non-empty section and name but empty contents'
		iRetCode = tIniFile % getString("Senseful", "Line_003", sValue, "Should not print this default")
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: empty string)'
		print *
		print *, 'Case 7: Checking case sensitiveness using a wrongly-cased key and default'
		iRetCode = tIniFile % getString("Senseful", "LINE_005", sValue, "... nunc in scutella iaceo.")
		if(iRetCode /= 0) then
			print *, 'Error no.', iRetCode
			stop
		end if
		print *,'Value: ', trim(sValue), '   (expected: ... nunc in scutella iaceo.)'
		print *
		
		! Test 3: get real*4 value from INI file
		print *, "Test 3: Get 32-bit floating point value from INI file"
		print *
		print *, "Case 1: Get existing real value from INI"
		iRetCode = tIniFile % getReal4("General", "Lat", rValue)
		print *, "Returned: ", rValue, "   (expected: 10.11; Return code:",iRetCode, ")"
		print *
		print *, "Case 2: Get non-existing real value (because of wrong char case) from INI, no default"
		iRetCode = tIniFile % getReal4("General", "LAT", rValue)
		print *, "Returned: ", rValue, "   (expected: NaN; Return code:",iRetCode, ")"
		print *
		print *, "Case 3: Get non-existing real value (because of wrong char case) from INI, default -9999.9"
		iRetCode = tIniFile % getReal4("General", "LAT", rValue, -9999.9)
		print *, "Returned: ", rValue, "   (expected: -9999.9; Return code:",iRetCode, ")"
		print *
		print *, "Case 4: Get existing but invalid real value from INI, no default"
		iRetCode = tIniFile % getReal4("Mysterious", "Mah", rValue)
		print *, "Returned: ", rValue, "   (expected: NaN; Return code:",iRetCode, ")"
		print *
		print *, "Case 5: Get existing but empty real value from INI, no default"
		iRetCode = tIniFile % getReal4("Senseful", "Line_003", rValue)
		print *, "Returned: ", rValue, "   (expected: NaN; Return code:",iRetCode, ")"
		print *
		
		! Test 4: get real*8 value from INI file
		print *, "Test 4: Get 64-bit floating point value from INI file"
		print *
		print *, "Case 1: Get existing real value from INI"
		iRetCode = tIniFile % getReal8("General", "Lat", rValue8)
		print *, "Returned: ", rValue8, "   (expected: 10.11; Return code:",iRetCode, ")"
		print *
		print *, "Case 2: Get non-existing real value (because of wrong char case) from INI, no default"
		iRetCode = tIniFile % getReal8("General", "LAT", rValue8)
		print *, "Returned: ", rValue8, "   (expected: NaN; Return code:",iRetCode, ")"
		print *
		print *, "Case 3: Get non-existing real value (because of wrong char case) from INI, default -9999.9"
		iRetCode = tIniFile % getReal8("General", "LAT", rValue8, -9999.9d0)
		print *, "Returned: ", rValue8, "   (expected: -9999.9; Return code:",iRetCode, ")"
		print *
		print *, "Case 4: Get existing but invalid real value from INI, no default"
		iRetCode = tIniFile % getReal8("Mysterious", "Mah", rValue8)
		print *, "Returned: ", rValue8, "   (expected: NaN; Return code:",iRetCode, ")"
		print *
		print *, "Case 5: Get existing but empty real value from INI, no default"
		iRetCode = tIniFile % getReal8("Senseful", "Line_003", rValue8)
		print *, "Returned: ", rValue8, "   (expected: NaN; Return code:",iRetCode, ")"
		print *
		
		! Test 5: get integer value from INI file
		print *, "Test 5: Get integer value from INI file"
		print *
		print *, "Case 1: Get existing integer value from INI"
		iRetCode = tIniFile % getInteger("Senseful", "Num_Lines", iValue)
		print *, "Returned: ", iValue, "   (expected: 5; Return code:",iRetCode, ")"
		print *
		print *, "Case 2: Get non-existing integer value (because of wrong char case) from INI, no default"
		iRetCode = tIniFile % getInteger("Senseful", "num_lines", iValue)
		print *, "Returned: ", iValue, "   (expected: -9999; Return code:",iRetCode, ")"
		print *
		print *, "Case 3: Get non-existing integer value (because of wrong char case) from INI, default 8888"
		iRetCode = tIniFile % getInteger("Senseful", "num_lines", iValue, 8888)
		print *, "Returned: ", iValue, "   (expected: 8888; Return code:",iRetCode, ")"
		print *
		print *, "Case 4: Get existing but invalid integer value from INI, no default"
		iRetCode = tIniFile % getInteger("General", "Lat", iValue)
		print *, "Returned: ", iValue, "   (expected: -9999; Return code:",iRetCode, ")"
		print *
		print *, "Case 5: Get existing but missing integer value from INI, no default"
		iRetCode = tIniFile % getInteger("Senseful", "Line_003", iValue)
		print *, "Returned: ", iValue, "   (expected: -9999; Return code:",iRetCode, ")"
		print *
		
	end subroutine tstIniFile
	
	
	subroutine tstIncompleteGamma()
	
		! Routine arguments
		! --none--
		
		! Locals
		real, dimension(:), allocatable	:: rvX
		real, dimension(:), allocatable	:: rvA
		real, dimension(:), allocatable	:: rvP_Exp
		real, dimension(:), allocatable	:: rvP_Act
		character(len=128)				:: sBuffer
		integer							:: i
		
		! Test 1: compare results with reference value from R (note: gappaP(x,a) = pgamma(a,x) in R
		print *, "Test 1: Incomplete gamma function vs reference values"
		allocate(rvX(56), rvA(56), rvP_Exp(56), rvP_Act(56))
		open(10, file="incomplete.gamma.csv", status='old', action='read')
		read(10,"(a)") sBuffer
		print *
		print *, "x, a, P.Expected, P.Actual, Difference"
		do i = 1, 56
			read(10, *) rvX(i), rvA(i), rvP_Exp(i)
			rvP_Act(i) = gammaP(rvA(i), rvX(i))
			print "(2(f4.1,','),e15.7,2(',',e15.7))", rvX(i), rvA(i), rvP_Exp(i), rvP_Act(i), rvP_Act(i) - rvP_Exp(i)
		end do
		close(10)
		deallocate(rvX, rvA, rvP_Exp, rvP_Act)
	
	end subroutine tstIncompleteGamma

end program t_pbl_base
