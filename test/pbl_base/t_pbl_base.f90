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

contains

	subroutine tstIniFile()
	
		! Routine arguments
		! -none-
		
		! Locals
		type(IniFile)	:: tIniFile
		integer			:: iRetCode
		
		! Test 1: Load test configuration, then dump it
		print *, 'Test 1 - Check INI read and decode on an existing file'
		iRetCode = tIniFile % read(10, "test.ini")
		if(iRetCode /= 0) then
			print *, 'Test 1 failed: please identify and correct the malfunction'
			stop
		end if
		iRetCode = tIniFile % dump()
		print *
		
	end subroutine tstIniFile

end program t_pbl_base
