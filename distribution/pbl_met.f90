! pbl_met.f90 - "Omnibus" distribution kit for the pbl_met library.
!
! It may be used to compile an own application without exiting 'gfortran', using
! the line
!
!	gfortran -fno-range-check -o <your_executable_name> <your_program.f90> pbl_met.f90 
!

! pbl_base - Fortran module, containing useful symbols and constants.
!
! This module is part of the pbl_met library.
!
! Copyright 2018 by Servizi Territorio srl
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_base

	use ieee_arithmetic

	implicit none

	private

	! Public interface
	! 0. Useful constants and symbols
	public	:: NaN							! Non-signalling single precision NaN (generates other NaNs when combined with other values)
	public	:: NaN_8						! Non-signalling double precision NaN (generates other NaNs when combined with other values)
	public	:: LAI_GRASS
	public	:: LAI_ALFALFA
	public	:: ASCE_STANDARDATMOSPHERE
	public	:: ASCE_STANDARDEQ
	public	:: ASCE_MEANTEMPERATURE
	public	:: ASCE_GRASS
	public	:: ASCE_ALFALFA
	public	:: ACV_GENERAL
	public	:: ACV_2ND_ORDER
	public	:: YEAR_DURATION
	public	:: MONTH_DURATION
	public	:: BASE_DAY
	public	:: BASE_DAY_8
	public	:: OS_UNIX
	public	:: OS_WIN
	! 1. Operators and procedures
	public	:: operator(.valid.)
	public	:: operator(.invalid.)
	public	:: toUpper
	public	:: toLower
	public	:: baseName
	public	:: gammaP	! Lower incomplete gamma function P(a,x)
	! 2. Data types
	public	:: IniFile
	public	:: Spline

	! Constants
    real, parameter		:: NaN				       = Z'7FC00000'			! Special case of non-signalling NaN (single precision)
    real(8), parameter	:: NaN_8			       = Z'7FF8000000000000'	! Special case of non-signalling NaN (double precision)
	real, parameter		:: YEAR_DURATION	       = 365.25
	real, parameter		:: MONTH_DURATION	       = 30.6001
	integer, parameter	:: BASE_DAY			       = 2440588		! 01. 01. 1970
	integer, parameter	:: BASE_DAY_8		       = 2440588_8		! 01. 01. 1970
	integer, parameter	:: LAI_GRASS               = 0
	integer, parameter	:: LAI_ALFALFA             = 1
	integer, parameter	:: ASCE_STANDARDATMOSPHERE = 0
	integer, parameter	:: ASCE_STANDARDEQ         = 1
	integer, parameter	:: ASCE_MEANTEMPERATURE    = 2
	integer, parameter	:: ASCE_GRASS              = 1
	integer, parameter	:: ASCE_ALFALFA            = 2
	integer, parameter	:: ACV_GENERAL             = 0
	integer, parameter	:: ACV_2ND_ORDER           = 1
	integer, parameter	:: OS_UNIX      	       = 0
	integer, parameter	:: OS_WIN		           = 1

	! Operators

	interface operator(.valid.)
		module procedure isValid
		module procedure isValid8
	end interface operator(.valid.)

	interface operator(.invalid.)
		module procedure isInvalid
		module procedure isInvalid8
	end interface operator(.invalid.)

	! Data types

	type IniFile
		logical, private										:: lIsUseable
		integer, private										:: iNumKeys
		character(len=256), dimension(:), allocatable, private	:: svLine
		character(len=256), dimension(:), allocatable, private	:: svKey
		character(len=256), dimension(:), allocatable, private	:: svValue
	contains
		! Constructor
		procedure, public	:: read       => iniRead
		procedure, public	:: dump       => iniDump
		procedure, public	:: getString  => iniGetString
		procedure, public	:: getReal4   => iniGetReal4
		procedure, public	:: getReal8   => iniGetReal8
		procedure, public	:: getInteger => iniGetInteger
	end type IniFile


	type Spline
		! Spline coefficients
		real(8), private, dimension(:), allocatable	:: x
		real(8), private, dimension(:), allocatable	:: y
		real(8), private, dimension(:), allocatable	:: b
		real(8), private, dimension(:), allocatable	:: c
		real(8), private, dimension(:), allocatable	:: d
		logical										:: lEquallySpaced
		logical										:: lIsOK
	contains
		procedure, public	:: init     => splInit
		procedure, public	:: evaluate => splEval
		procedure, public	:: vectEval => splEvalVect
	end type Spline

contains

	! Check a value is valid, that is, not a NaN.

	pure elemental function isValid(value) result(valid)

		! Routine arguments
		real, intent(in)	:: value	! Value to check
		logical				:: valid	! Check result

		! Locals
		! -none-

		! Check validity
		valid = .not.ieee_is_nan(value)

	end function isValid

	pure elemental function isValid8(value) result(valid)

		! Routine arguments
		real(8), intent(in)	:: value	! Value to check
		logical				:: valid	! Check result

		! Locals
		! -none-

		! Check validity
		valid = .not.ieee_is_nan(value)

	end function isValid8


	! Check a value is invalid, that is, a NaN.

	pure elemental function isInvalid(value) result(invalid)

		! Routine arguments
		real, intent(in)	:: value	! Value to check
		logical				:: invalid	! Check result

		! Locals
		! -none-

		! Check validity
		invalid = ieee_is_nan(value)

	end function isInvalid

	pure elemental function isInvalid8(value) result(invalid)

		! Routine arguments
		real(8), intent(in)	:: value	! Value to check
		logical				:: invalid	! Check result

		! Locals
		! -none-

		! Check validity
		invalid = ieee_is_nan(value)

	end function isInvalid8


	subroutine toUpper(sString)

		! Routine arguments
		character(len=*), intent(inout)	:: sString

		! Locals
		integer		:: i
		character	:: c

		! Change all alphabetic letters to uppercase
		do i = 1, len_trim(sString)
			c = sString(i:i)
			if(c >= 'a' .and. c <= 'z') then
				c = char(ichar(c) - ichar('a') + ichar('A'))
			end if
		end do

	end subroutine toUpper


	subroutine toLower(sString)

		! Routine arguments
		character(len=*), intent(inout)	:: sString

		! Locals
		integer		:: i
		character	:: c

		! Change all alphabetic letters to lowercase
		do i = 1, len_trim(sString)
			c = sString(i:i)
			if(c >= 'A' .and. c <= 'Z') then
				c = char(ichar(c) - ichar('A') + ichar('a'))
			end if
		end do

	end subroutine toLower


	function baseName(sFileName, iOS) result(sName)

		! Routine arguments
		character(len=*), intent(in)	:: sFileName
		integer, intent(in)				:: iOS			! Operating system type (OS_WIN: Windows; OS_UNIX: Linux, UNIX, OS/X)
		character(len=256)				:: sName

		! Locals
		integer		:: iPos
		character	:: sDelimiter

		! Set delimiter based on OS type
		if(iOS == OS_UNIX) then
			sDelimiter = "/"
		elseif(iOS == OS_WIN) then
			sDelimiter = "\\"
		else
			sName = sFileName
			return
		end if

		! Find last delimiter in string, and if found return all characters on right of it;
		! otherwise, return the input string unchanged
		iPos = index(sFileName, sDelimiter, back=.true.)
		if(iPos > 0) then
			sName = sFileName(iPos+1:)
		else
			sName = sFileName
		end if

	end function baseName


	function gammaP(a, x, iMaxIterations) result(gP)

		! Routine arguments
		real, intent(in)				:: a
		real, intent(in)				:: x
		integer, intent(in), optional	:: iMaxIterations
		real							:: gP

		! Locals
		integer	:: i
		integer	:: iMaxIter
		real	:: delta
		real	:: accumulator
		real	:: p, b, c, d, h, tmp
		real	:: fpmin

		! Check input parameters
		if(x < 0. .or. a <= 0.) then
			gP = NaN
			return
		end if
		if(present(iMaxIterations)) then
			if(iMaxIterations < 10) then
				gP = NaN
				return
			end if
		end if

		! Assign maximum iteration number
		if(present(iMaxIterations)) then
			iMaxIter = iMaxIterations
		else
			iMaxIter = 100
		end if

		! Dispatch execution based on parameter value
		if(x < a + 1.) then
			! More convenient to use the series expansion here
			p           = a
			delta       = 1./a
			accumulator = delta
			gP          = NaN
			do i = 1, iMaxIter
				p           = p + 1.
				delta       = delta * x / p
				accumulator = accumulator + delta
				if(abs(delta) < abs(accumulator)*epsilon(delta)*4.) then
					gP = accumulator * exp(-x + a*log(x) - log_gamma(a))
					exit
				end if
			end do
		else
			! Here it is better to use the continued fraction approximation
			fpmin = 4./huge(fpmin)
			b     = x + 1.0 - a
			c     = 1. / fpmin
			d     = 1. / b
			h     = d
			gP    = NaN
			do i = 1, iMaxIter
				tmp = -i * (i - a)
				b   = b + 2.
				d   = tmp*d + b
				if(abs(d) < fpmin) d = fpmin
				c   = b + tmp/c
				if(abs(c) < fpmin) c = fpmin
				d   = 1. / d
				delta = d * c
				h   = h * delta
				if(abs(delta - 1.) < epsilon(delta)*4.) then
					gP = h * exp(-x + a*log(x) - log_gamma(a))
					exit
				end if
			end do
			gP = 1. - gP
		end if

	end function gammaP


	function iniRead(this, iLUN, sIniFileName) result(iRetCode)

		! Routine arguments
		class(IniFile), intent(inout)	:: this
		integer, intent(in)				:: iLUN
		character(len=*), intent(in)	:: sIniFileName
		integer							:: iRetCode

		! Locals
		integer				:: iErrCode
		character(len=256)	:: sBuffer
		character(len=256)	:: sCurrentSection
		character(len=256)	:: sCurSection
		integer				:: iNumLines
		integer				:: iLine
		integer				:: iPos
		integer				:: iNumKeys
		integer				:: i

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Clean state before to proceed
		this % lIsUseable = .false.
		if(allocated(this % svLine)) deallocate(this % svLine)
		if(allocated(this % svKey)) deallocate(this % svKey)
		if(allocated(this % svValue)) deallocate(this % svValue)

		! Now, count lines excluding comments
		open(iLUN, file=sIniFileName, status='old', action='read', iostat=iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 1
			return
		end if
		iNumLines = 0
		do

			! Try gathering a line, and if acquired replace all characters
			! from the first '#' on with blanks
			read(iLun, "(a)", iostat=iErrCode) sBuffer
			if(iErrCode /= 0) exit
			iPos = index(sBuffer, "#")
			if(iPos > 0) sBuffer(iPos:) = ' '

			! Replace TABs and other spaces with regular blanks
			do i = 1, len(sBuffer)
				if(ichar(sBuffer(i:i)) < 32) sBuffer(i:i) = ' '
			end do
			if(sBuffer == ' ') cycle
			! Post-condition: something remains

			! Increment line count, remembering lines which may be subject to parsing
			iNumLines = iNumLines + 1

		end do
		if(iNumLines <= 0) then
			close(iLun)
			iRetCode = 2
			return
		end if
		rewind(iLUN)

		! Reserve workspace, and populate it with non-comment lines
		allocate(this % svLine(iNumLines), this % svKey(iNumLines), this % svValue(iNumLines))
		iLine = 0
		do

			! Try gathering a line, and if acquired replace all characters
			! from the first '#' on with blanks
			read(iLun, "(a)", iostat=iErrCode) sBuffer
			if(iErrCode /= 0) exit
			iPos = index(sBuffer, "#")
			if(iPos > 0) sBuffer(iPos:) = ' '

			! Replace TABs and other spaces with regular blanks
			do i = 1, len(sBuffer)
				if(ichar(sBuffer(i:i)) < 32) sBuffer(i:i) = ' '
			end do
			if(sBuffer == ' ') cycle
			! Post-condition: something remains

			! Add next line
			iLine = iLine + 1
			this % svLine(iLine) = sBuffer

		end do
		close(iLUN)
		! Post-condition: Some lines found

		! Parse line contents
		sCurrentSection = ""
		iNumKeys        = 0
		do iLine = 1, iNumLines

			! Check string is a section, and if so assign it
			if(isSection(this % svLine(iLine), sCurSection)) then
				sCurrentSection = sCurSection
			else
				! Not a section: may contain an equal sign, that is, to be a name = value couple
				iPos = index(this % svLine(iLine), "=")
				if(iPos > 0) then
					iNumKeys = iNumKeys + 1
					write(this % svKey(iNumKeys), "(a,'@',a)") &
						trim(sCurrentSection), adjustl(this % svLine(iLine)(1:(iPos-1)))
					this % svValue(iNumKeys) = adjustl(this % svLine(iLine)((iPos+1):))
					call removeChar(this % svValue(iNumKeys), '"')
				end if
			end if

		end do

		! Confirm successful completion
		this % lIsUseable = .true.
		this % iNumKeys   = iNumKeys

	end function iniRead


	function iniDump(this) result(iRetCode)

		! Routine arguments
		class(IniFile), intent(in)	:: this
		integer						:: iRetCode

		! Locals
		integer	:: i
		integer	:: iKeyLen

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check whether the dump is to be make in full,
		! that is, the INI file read has completed successfully
		! and the data structures have been filled
		if(this % lIsUseable) then

			! Check length to constrain keys to when printing
			iKeyLen = 0
			do i = 1, this % iNumKeys
				iKeyLen = max(iKeyLen, len_trim(this % svKey(i)))
			end do

			! Print all keys, and their associated values. To print
			! keys in column the maximum key length is used, along with
			! the fact that in Fortran all strings in an array share
			! the same length and are blank-filled on right. The approach
			! I've followed would have *not* worked in C and other
			! variable-length string languages.
			do i = 1, this % iNumKeys
				print "(a,' -> ',a)", this % svKey(i)(1:iKeyLen), trim(this % svValue(i))
			end do

		else

			print *, "INI data contents has not yet been assigned, nothing to print"
			iRetCode = 1

		end if

	end function iniDump


	function iniGetString(this, sSection, sKey, sValue, sDefault) result(iRetCode)

		! Routine arguments
		class(IniFile), intent(inout)			:: this
		character(len=*), intent(in)			:: sSection
		character(len=*), intent(in)			:: sKey
		character(len=*), intent(out)			:: sValue
		character(len=*), intent(in), optional	:: sDefault
		integer									:: iRetCode

		! Locals
		integer				:: i
		character(len=256)	:: sFullKey

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be made
		if(this % iNumKeys > 0) then

			! Yes: there are data lines to scan
			write(sFullKey, "(a, '@', a)") trim(sSection), trim(sKey)
			do i = 1, this % iNumKeys
				if(this % svKey(i) == sFullKey) then
					sValue = this % svValue(i)
					return
				end if
			end do

			! Nothing found if execution reaches here: in case,
			! yield the default (if present) or a blank (otherwise).
			if(present(sDefault)) then
				sValue = sDefault
			else
				sValue = ' '
			end if

		else

			! No INI data available: flag an error condition.
			if(present(sDefault)) then
				sValue = sDefault
			else
				sValue = ' '
			end if
			iRetCode = 1

		end if

	end function iniGetString


	function iniGetReal4(this, sSection, sKey, rValue, rDefault) result(iRetCode)

		! Routine arguments
		class(IniFile), intent(inout)			:: this
		character(len=*), intent(in)			:: sSection
		character(len=*), intent(in)			:: sKey
		real, intent(out)						:: rValue
		real, intent(in), optional				:: rDefault
		integer									:: iRetCode

		! Locals
		character(len=32)	:: sValue
		real				:: rReplace
		integer				:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Assign the replacement value based on rDefault
		if(present(rDefault)) then
			rReplace = rDefault
		else
			rReplace = NaN
		end if

		! Gather the string supposedly containing the floating point value to transfer
		iErrCode = this % getString(sSection, sKey, sValue)
		if(iErrCode /= 0) then
			rValue = rReplace
			iRetCode = 1
			return
		end if
		! Post-condition: iRetCode was 0 from now on

		! Check the value found to be not empty
		if(sValue == ' ') then
			rValue = rReplace
			iRetCode = 2
			return
		end if

		! Ok, something was found: but, it might not be a floating point value:
		! try converting it and, in case of failure, yield an error
		read(sValue, *, iostat=iErrCode) rValue
		if(iErrCode /= 0) then
			rValue = rReplace
			iRetCode = 3
		end if
		! Post-condition: 'rValue' has been assigned correctly, and on
		! function exit will be restituted regularly

	end function iniGetReal4


	function iniGetReal8(this, sSection, sKey, rValue, rDefault) result(iRetCode)

		! Routine arguments
		class(IniFile), intent(inout)			:: this
		character(len=*), intent(in)			:: sSection
		character(len=*), intent(in)			:: sKey
		real(8), intent(out)					:: rValue
		real(8), intent(in), optional			:: rDefault
		integer									:: iRetCode

		! Locals
		character(len=32)	:: sValue
		real(8)				:: rReplace
		integer				:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Assign the replacement value based on rDefault
		if(present(rDefault)) then
			rReplace = rDefault
		else
			rReplace = NaN_8
		end if

		! Gather the string supposedly containing the floating point value to transfer
		iErrCode = this % getString(sSection, sKey, sValue)
		if(iErrCode /= 0) then
			rValue = rReplace
			iRetCode = 1
			return
		end if
		! Post-condition: iRetCode was 0 from now on

		! Check the value found to be not empty
		if(sValue == ' ') then
			rValue = rReplace
			iRetCode = 2
			return
		end if

		! Ok, something was found: but, it might not be a floating point value:
		! try converting it and, in case of failure, yield an error
		read(sValue, *, iostat=iErrCode) rValue
		if(iErrCode /= 0) then
			rValue = rReplace
			iRetCode = 3
		end if
		! Post-condition: 'rValue' has been assigned correctly, and on
		! function exit will be restituted regularly

	end function iniGetReal8


	function iniGetInteger(this, sSection, sKey, iValue, iDefault) result(iRetCode)

		! Routine arguments
		class(IniFile), intent(inout)			:: this
		character(len=*), intent(in)			:: sSection
		character(len=*), intent(in)			:: sKey
		integer, intent(out)					:: iValue
		integer, intent(in), optional			:: iDefault
		integer									:: iRetCode

		! Locals
		character(len=32)	:: sValue
		integer				:: iReplace
		integer				:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Assign the replacement value based on rDefault
		if(present(iDefault)) then
			iReplace = iDefault
		else
			iReplace = -9999
		end if

		! Gather the string supposedly containing the floating point value to transfer
		iErrCode = this % getString(sSection, sKey, sValue)
		if(iErrCode /= 0) then
			iValue = iReplace
			iRetCode = 1
			return
		end if
		! Post-condition: iRetCode was 0 from now on

		! Check the value found to be not empty
		if(sValue == ' ') then
			iValue = iReplace
			iRetCode = 2
			return
		end if

		! Ok, something was found: but, it might not be a floating point value:
		! try converting it and, in case of failure, yield an error
		read(sValue, *, iostat=iErrCode) iValue
		if(iErrCode /= 0) then
			iValue = iReplace
			iRetCode = 3
		end if
		! Post-condition: 'iValue' has been assigned correctly, and on
		! function exit will be restituted regularly

	end function iniGetInteger


	function splInit(this, rvX, rvY) result(iRetCode)

		! Routine arguments
		class(Spline), intent(out)			:: this
		real(8), dimension(:), intent(in)	:: rvX
		real(8), dimension(:), intent(in)	:: rvY
		integer								:: iRetCode

		! Locals
		integer		:: n
		integer		:: i, j, gap
		real(8)		:: h
		logical		:: lNoGaps
		real(8)		:: rDelta
		real(8)		:: rIndex

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		n = size(rvX)
		if(n < 2) then
			iRetCode = 1
			return
		end if
		if(size(rvY) /= n) then
			iRetCode = 2
			return
		end if
		lNoGaps = .true.
		do i = 1, n
			if((.invalid.rvX(i)) .or. (.invalid.rvY(i))) then
				lNoGaps = .false.
				exit
			end if
		end do
		if(.not.lNoGaps) then
			iRetCode = 3
			return
		end if
		do i = 2, n
			if(rvX(i) <= rvX(i-1)) then
				iRetCode = 4
				return
			end if
		end do

		! Check the rvX values are equally spaced (a particularly important special case)
		rDelta = rvX(2) - rvX(1)
		this % lEquallySpaced = .false.
		do i = 2, n
			rIndex = (rvX(i)-rvX(1)) / rDelta
			if(rIndex - floor(rIndex) >= 1.d-3) then
				this % lEquallySpaced = .false.
				exit
			end if
		end do

		! Reserve workspace
		if(allocated(this % x)) deallocate(this % x)
		if(allocated(this % y)) deallocate(this % y)
		if(allocated(this % b)) deallocate(this % b)
		if(allocated(this % c)) deallocate(this % c)
		if(allocated(this % d)) deallocate(this % d)
		allocate(this % x(n))
		allocate(this % y(n))
		allocate(this % b(n))
		allocate(this % c(n))
		allocate(this % d(n))

		! Save data points
		this % x = rvX
		this % y = rvY

		! Check the number of points allows the existence of a third-degree spline
		if(n < 3) then
			! Not enough points: perform plain linear interpolation
			this % b(1) = (rvY(2)-rvY(1))/(rvX(2)-rvX(1))
			this % c(1) = 0.
			this % d(1) = 0.
			this % b(2) = this % b(1)
			this % c(2) = 0.
			this % d(2) = 0.
			return
		end if

		! Prepare
		gap = n-1
		this % d(1) = this % x(2) - this % x(1)
		this % c(2) = (this % y(2) - this % y(1))/this % d(1)
		do i = 2, gap
			this % d(i) = this % x(i+1) - this % x(i)
			this % b(i) = 2.0*(this % d(i-1) + this % d(i))
			this % c(i+1) = (this % y(i+1) - this % y(i))/this % d(i)
			this % c(i) = this % c(i+1) - this % c(i)
		end do

		! Enforce boundary conditions
		this % b(1) = -this % d(1)
		this % b(n) = -this % d(n-1)
		this % c(1) = 0.0
		this % c(n) = 0.0
		if(n /= 3) then
			this % c(1) = this % c(3) / (this % x(4) - this % x(2)) - this % c(2) / (this % x(3) - this % x(1))
			this % c(n) = this % c(n-1) / (this % x(n) - this % x(n-2)) - this % c(n-2) / (this % x(n-1) - this % x(n-3))
			this % c(1) = this % c(1) * this % d(1)**2 / (this % x(4) - this % x(1))
			this % c(n) = -this % c(n) * this % d(n-1)**2 / (this % x(n) - this % x(n-3))
		end if

		! Solution step 1: forward substitution
		do i = 2, n
			h = this % d(i-1) / this % b(i-1)
			this % b(i) = this % b(i) - h * this % d(i-1)
			this % c(i) = this % c(i) - h * this % c(i-1)
		end do

		! Solution step 2: back substitution
		this % c(n) = this % c(n) / this % b(n)
		do j = 1, gap
			i = n-j
			this % c(i) = (this % c(i) - this % d(i) * this % c(i+1)) / this % b(i)
		end do

		! Final coefficients calculation
		this % b(n) = (this % y(n) - this % y(gap)) / this % d(gap) + this % d(gap)*(this % c(gap) + 2.d0 * this % c(n))
		do i = 1, gap
			this % b(i) = (this % y(i+1) - this % y(i)) / this % d(i) - this % d(i) * (this % c(i+1) + 2.d0 * this % c(i))
			this % d(i) = (this % c(i+1) - this % c(i)) / this % d(i)
			this % c(i) = 3.d0 * this % c(i)
		end do
		this % c(n) = 3.d0 * this % c(n)
		this % d(n) = this % d(n-1)

		! Inform users evaluations may occur
		this % lIsOK = .true.

	end function splInit


	function splEval(this, rX) result(rValue)

		! Routine arguments
		class(Spline), intent(in)	:: this
		real(8), intent(in)			:: rX
		real(8)						:: rValue

		! Locals
		integer	:: n
		integer	:: i
		integer	:: j
		integer	:: k
		real(8)	:: dx

		! Use boundary values outside the 'x' interval
		n = size(this % x)
		if(rX < this % x(1)) then
			rValue = this % y(1)
			return
		elseif(rX > this % x(n)) then
			rValue = this % y(n)
			return
		end if

		! Find index i such that x(i) <= rX <= x(i+1)
		if(this % lEquallySpaced) then
			! Find index directly
			i = floor((rX - this % x(1)) / (this % x(2) - this % x(1))) + 1
		else
			! Find index by binary search
			i = 1
			j = n+1
			do while(j > i+1)
				k = (i+j)/2
				if(rX < this % x(k)) then
					j=k
				else
					i=k
				end if
			end do
		end if

		! Evaluate spline
		dx = rX - this % x(i)
		rValue = this % y(i) + dx * (this % b(i) + dx * (this % c(i) + dx * this % d(i)))

	end function splEval


	function splEvalVect(this, rvX, rvY) result(iRetCode)

		! Routine arguments
		class(Spline), intent(in)				:: this
		real(8), dimension(:), intent(in)		:: rvX
		real(8), dimension(:), intent(out)		:: rvY
		integer									:: iRetCode

		! Locals
		integer	:: m
		integer	:: n
		integer	:: i
		integer	:: j
		integer	:: k
		integer	:: l
		real(8)	:: dx

		! Assume seccess (will falsify on failure)
		iRetCode = 0

		! Check values
		m = size(rvX)
		if(size(rvY) /= m) then
			iRetCode = 1
			return
		end if

		n = size(this % x)

		! Main loop: iterate over 'rvX' values
		do l = 1, m

			! Use boundary values outside the 'x' interval
			if(rvX(l) < this % x(1)) then
				rvY(l) = this % y(1)
				cycle
			elseif(rvX(l) > this % x(n)) then
				rvY(l) = this % y(n)
				cycle
			end if

			! Find index i such that x(i) <= rX <= x(i+1)
			if(this % lEquallySpaced) then
				! Find index directly
				i = floor((rvX(l) - this % x(1)) / (this % x(2) - this % x(1))) + 1
			else
				! Find index by binary search
				i = 1
				j = n+1
				do while(j > i+1)
					k = (i+j)/2
					if(rvX(l) < this % x(k)) then
						j=k
					else
						i=k
					end if
				end do
			end if

			! Evaluate spline
			dx = rvX(l) - this % x(i)
			rvY(l) = this % y(i) + dx * (this % b(i) + dx * (this % c(i) + dx * this % d(i)))

		end do

	end function splEvalVect


	! **********************
	! * Internal functions *
	! **********************

	function isSection(sString, sSection) result(lIsSection)

		! Routine arguments
		character(len=*), intent(in)	:: sString
		character(len=*), intent(out)	:: sSection
		logical							:: lIsSection

		! Locals
		integer		:: iPos
		integer		:: iLast

		! Check first and last character are compatible with a section-type string
		iPos = verify(sString, ' ')
		iLast = len_trim(sString)
		if(iPos >= 1 .and. iPos <= iLast) then
			! Some blanks before the string real beginning: parse from there
			lIsSection = sString(iPos:iPos) == '[' .and. sString(iLast:iLast) == ']'
			if(lIsSection) then
				sSection = sString((iPos+1):(iLast-1))
			else
				sSection = ' '
			end if
		else
			! String begins with a non-blank
			lIsSection = sString(1:1) == '[' .and. sString(iLast:iLast) == ']'
			if(lIsSection) then
				sSection = sString(1:(iLast-1))
			else
				sSection = ' '
			end if
		end if

	end function isSection


	subroutine removeChar(sString, cChar)

		! Routine arguments
		character(len=*), intent(inout)	:: sString
		character, intent(in)			:: cChar

		! Locals
		integer	:: i, j, n

		! Copy all desired characters, and them only, to the string, in place
		n = len_trim(sString)
		j = 0
		do i = 1, n
			if(sString(i:i) /= cChar) then
				j = j + 1
				if(j /= i) then
					sString(j:j) = sString(i:i)
				end if
			end if
		end do
		if(j < n) then
			sString((j+1):n) = ' '
		end if

	end subroutine removeChar

end module pbl_base


! pbl_time - Fortran module, containing computations related to
!            Planetary Boundary Layer (PBL) quantities, encompassing
! date and time processing, and some astronomical formulae dealing
! with sunset/sunrise and apparent solar position.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_time

	use pbl_base

	implicit none

	private

	! Public interface
	! 0. Constants
	public	:: DELTA_1_HOUR
	public	:: DELTA_8_HOURS
	public	:: DELTA_1_DAY
	public	:: CLP_YEAR
	public	:: CLP_MONTH
	public	:: CLP_DAY
	public	:: CLP_HOUR
	public	:: CLP_MINUTE
	public	:: CLP_SECOND
	! 1. Date and time management
	public	:: JulianDay					! Integer-valued Julian day
	public	:: UnpackDate					! Inverse of integer-valued Julian day
	public	:: DoW							! Day-of-week
	public	:: DoY							! Day-of-year, as in old PBL_MET "J_DAY" routine
	public	:: Leap							! Check a year is leap or not
	public	:: PackTime						! Date and time to epoch
	public	:: UnpackTime					! Epoch to date and time
	! 2. Basic astronomical computations
	public	:: calcJD						! Fractional Julian day, defined according to NOAA conventions
	public	:: calcTimeJulianCent			! Fractional Julian century, defined according to NOAA conventions
	public	:: SinSolarElevation			! Compute the sine of solar elevation angle
	public	:: SolarDeclination				! Compute the solar declination
	public	:: SunRiseSunSet				! Old PBL_MET evaluation of sun rise and sun set times (revised)
	! 3. Data types
	public	:: DateTime						! Class, supporting the new REAL(8) time stamps used in Time Series
	public	:: operator(.sensible.)			! Check a date and time is valid and in range
	! 4. Support for time stamps as vectors
	public	:: timeEncode					! Compute aggregation indices for a time stamp vector
	public	:: timeLinearIndex				! Compute a linear aggregation index for a time stamp vector
	public	:: timeGetYear					! Extract year from a time stamp vector (may be used to obtain an index)
	public	:: timeGetMonth					! Extract month from a time stamp vector (may be used to obtain an index)
	public	:: timeGetYearMonth				! Extract a year-month value from a time stamp vector (may be used to obtain an index)
	public	:: timeSequence					! Generate a sequence of time stamps between two given initial and final time stamps
	! 5. Round time stamps to various common steps
	public	:: timeFloorDay					! Day stamp of current time stamp
	public	:: timeFloorHour				! Hour stamp of current time stamp
	public	:: timeCeilingDay				! Day stamp of next time stamp
	public	:: timeCeilingHour				! Hour stamp of next time stamp

	! Constants
	integer, parameter	:: DELTA_1_HOUR  = 3600
	integer, parameter	:: DELTA_8_HOURS = DELTA_1_HOUR * 8
	integer, parameter	:: DELTA_1_DAY   = DELTA_1_HOUR * 24
	integer, parameter	:: CLP_YEAR      = 1
	integer, parameter	:: CLP_MONTH     = 2
	integer, parameter	:: CLP_DAY       = 3
	integer, parameter	:: CLP_HOUR      = 4
	integer, parameter	:: CLP_MINUTE    = 5
	integer, parameter	:: CLP_SECOND    = 6

	! Data types
	type DateTime
		integer	:: iYear
		integer	:: iMonth
		integer	:: iDay
		integer	:: iHour
		integer	:: iMinute
		real(8)	:: rSecond
	contains
		! Constructors
		procedure	:: fromEpoch	=> dtFromEpoch
		! Converters
		procedure	:: toEpoch		=> dtToEpoch
		! Printers
		procedure	:: toIso		=> dtToIso
		! Calculators
		procedure	:: sunRiseSet	=> dtSunRiseSet
	end type DateTime

	! Internal constants
	real(8), parameter	:: TIME_MIN =            0.d0
	real(8), parameter	:: TIME_MAX = 253402300800.d0

	! Polymorphic interfaces

	interface timeEncode
		module procedure	:: timeEncode1
		module procedure	:: timeEncode2
	end interface timeEncode


	interface timeLinearIndex
		module procedure	:: timeLinearIndex1
		module procedure	:: timeLinearIndex2
	end interface timeLinearIndex


	interface timeGetYear
		module procedure	:: timeGetYear1
		module procedure	:: timeGetYear2
	end interface timeGetYear


	interface timeGetMonth
		module procedure	:: timeGetMonth1
		module procedure	:: timeGetMonth2
	end interface timeGetMonth


	interface timeGetYearMonth
		module procedure	:: timeGetYearMonth1
		module procedure	:: timeGetYearMonth2
	end interface timeGetYearMonth


	interface timeSequence
		module procedure	:: timeSequence1
		module procedure	:: timeSequence2
	end interface timeSequence


	interface timeFloorDay
		module procedure	:: timeFloorDay1
		module procedure	:: timeFloorDay2
	end interface timeFloorDay


	interface timeCeilingDay
		module procedure	:: timeCeilingDay1
		module procedure	:: timeCeilingDay2
	end interface timeCeilingDay


	interface timeFloorHour
		module procedure	:: timeFloorHour1
		module procedure	:: timeFloorHour2
	end interface timeFloorHour


	interface timeCeilingHour
		module procedure	:: timeCeilingHour1
		module procedure	:: timeCeilingHour2
	end interface timeCeilingHour


	interface operator(.sensible.)
		module procedure	:: isSensible
	end interface operator(.sensible.)

contains

	function JulianDay(iYear, iMonth, iDay) result(iJulianDay)

		! Routine arguments
        integer, intent(in) :: iYear
        integer, intent(in) :: iMonth
        integer, intent(in) :: iDay
        integer             :: iJulianDay

        ! Locals
        integer     		:: iAuxYear
        integer     		:: iAuxMonth
        integer     		:: iCentury
        integer     		:: iTryJulianDay
        integer     		:: iNumDays
        integer, parameter  :: DATE_REFORM_DAY = 588829 ! 15 October 1582, with 31-days months
        integer, parameter  :: BASE_DAYS       = 1720995

        ! Check year against invalid values. Only positive
        ! years are supported in this version. Year "0" does
        ! not exist.
        if(iYear <= 0) then
            iJulianDay = -9999
            return
        end if

        ! Check month and day to look valid (a rough, non-month-aware
        ! test is intentionally adopted in sake of simplicity)
        if((.not.(1<=iMonth .and. iMonth<=12)) .or. (.not.(1<=iDay .and. iDay<=31))) then
            iJulianDay = -9999
            return
        end if

        ! Preliminary estimate the Julian day, based on
        ! the average duration of year and month in days.
        if(iMonth > 2) then
            iAuxYear  = iYear
            iAuxMonth = iMonth + 1
        else
            iAuxYear  = iYear - 1
            iAuxMonth = iMonth + 13
        end if
        iTryJulianDay = floor(YEAR_DURATION * iAuxYear) + &
                        floor(MONTH_DURATION * iAuxMonth) + &
                        iDay + BASE_DAYS

        ! Correct estimate if later than the date reform day
        iNumDays = iDay + 31*iMonth + 372*iYear
        if(iNumDays >= DATE_REFORM_DAY) then
            iCentury = 0.01*iAuxYear
            iJulianDay = iTryJulianDay - iCentury + iCentury/4 + 2
        else
            iJulianDay = iTryJulianDay
        end if

	end function JulianDay


    subroutine UnpackDate(iJulianDay, iYear, iMonth, iDay)

        ! Routine arguments
        integer, intent(in)     :: iJulianDay
        integer, intent(out)    :: iYear
        integer, intent(out)    :: iMonth
        integer, intent(out)    :: iDay

        ! Locals
        integer :: iDeviation
        integer :: iPreJulianDay
        integer :: iPostJulianDay
        integer :: iYearIndex
        integer :: iMonthIndex
        integer :: iDayIndex
        integer, parameter  :: LIMIT_JULIAN_DAY = 2299161
        integer, parameter  :: CORRECTION_DAYS  = 1524

        ! Unwind Pope Gregorius' day correction
        if(iJulianDay >= LIMIT_JULIAN_DAY) then
            iDeviation = floor(((iJulianDay-1867216)-0.25)/36524.25)
            iPreJulianDay = iJulianDay + iDeviation - iDeviation/4 + 1
        else
            iPreJulianDay = iJulianDay
        end if
        iPostJulianDay = iPreJulianDay + CORRECTION_DAYS

        ! Compute time indices
        iYearIndex  = floor(6680+((iPostJulianDay-2439870)-122.1)/YEAR_DURATION)
        iDayIndex   = 365*iYearIndex + iYearIndex/4
        iMonthIndex = floor((iPostJulianDay - iDayIndex)/MONTH_DURATION)

        ! Deduce preliminary date from time indices
        iDay = iPostJulianDay - floor(MONTH_DURATION*iMonthIndex) - iDayIndex
        if(iMonthIndex > 13) then
            iMonth = iMonthIndex - 13
        else
            iMonth = iMonthIndex - 1
        end if
        iYear = iYearIndex - 4715
        if(iMonth > 2) iYear = iYear - 1

    end subroutine UnpackDate


	! Definition of even-leap year
	function Leap(ia) result(isLeap)

		! Routine arguments
		integer, intent(in)	:: ia
		logical				:: isLeap

		! Locals
		! --none--

		! Check the year is leap according to the standard definition
		if(mod(ia,4) /= 0) then
			! Year, not divisible by 4, is surely even
			isLeap = .false.
		else
			! Year is divisible by 4
			if(mod(ia,100) == 0) then
				if(mod(ia,400) == 0) then
					isLeap = .true.
				else
					isLeap = .false.
				end if
			else
				isLeap = .true.
			end if
		end if

	end function Leap


    function DoW(iJulianDay) result(iDayOfWeek)

        ! Routine arguments
        integer, intent(in) :: iJulianDay
        integer         	:: iDayOfWeek

        ! Locals
        ! -none-

        ! Compute the desired quantity
        iDayOfWeek = mod(iJulianDay, 7)

    end function DoW


	! Day of year
	function DoY(ia,im,id) result(iDayOfYear)

		! Routine arguments
		integer, intent(in)	:: ia			! Year (with century)
		integer, intent(in)	:: im			! Month
		integer, intent(in)	:: id			! Day
		integer				:: iDayOfYear	! Day in year

		! Locals
		! --none--

		! Parameters
		integer, dimension(13,2), parameter	:: ngm = reshape( &
			[0,31,60,91,121,152,182,213,244,274,305,335,366, &
			 0,31,59,90,120,151,181,212,243,273,304,334,365], [13,2])

		if(Leap(ia)) then
			! Leap year
			iDayOfYear = id+ngm(im,1)
		else
			! Even year
			iDayOfYear = id+ngm(im,2)
		end if

	end function DoY


    subroutine PackTime(iTime, iYear, iMonth, iDay, iInHour, iInMinute, iInSecond)

        ! Routine arguments
        integer, intent(out)            :: iTime
        integer, intent(in)             :: iYear
        integer, intent(in)             :: iMonth
        integer, intent(in)             :: iDay
        integer, intent(in), optional   :: iInHour
        integer, intent(in), optional   :: iInMinute
        integer, intent(in), optional   :: iInSecond

        ! Locals
        integer :: iHour
        integer :: iMinute
        integer :: iSecond
        integer :: iJulianDay
        integer :: iJulianSecond

        ! Check for optional parameters; assign defaults if necessary
        if(present(iInHour)) then
            iHour = iInHour
        else
            iHour = 0
        end if
        if(present(iInMinute)) then
            iMinute = iInMinute
        else
            iMinute = 0
        end if
        if(present(iInSecond)) then
            iSecond = iInSecond
        else
            iSecond = 0
        end if

        ! Check input parameters for validity
        if( &
            iYear   <= 0 .OR. &
            iMonth  < 1 .OR. iMonth  > 12 .OR. &
            iDay    < 1 .OR. iDay    > 31 .OR. &
            iHour   < 0 .OR. iHour   > 23 .OR. &
            iMinute < 0 .OR. iMinute > 59 .OR. &
            iSecond < 0 .OR. iSecond > 59 &
        ) then
            iTime = -1
            return
        end if

        ! Compute based Julian day
        iJulianDay = JulianDay(iYear, iMonth, iDay) - BASE_DAY

        ! Convert based Julian day to second, and add seconds from time,
        ! regardless of hour type.
        iJulianSecond = iJulianDay * 24 * 3600
        iTime = iJulianSecond + iSecond + 60*(iMinute + 60*iHour)

    end subroutine PackTime


    subroutine UnpackTime(iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond)

        ! Routine arguments
        integer, intent(in)     :: iTime
        integer, intent(out)    :: iYear
        integer, intent(out)    :: iMonth
        integer, intent(out)    :: iDay
        integer, intent(out)    :: iHour
        integer, intent(out)    :: iMinute
        integer, intent(out)    :: iSecond

        ! Locals
        integer :: iJulianDay
        integer :: iTimeSeconds

        ! Check parameter
        if(iTime < 0) then
            iYear   = 1970
            iMonth  = 1
            iDay    = 1
            iHour   = 0
            iMinute = 0
            iSecond = 0
            return
        end if

        ! Isolate the date and time parts
        iJulianDay = iTime/(24*3600) + BASE_DAY
        iTimeSeconds = mod(iTime, 24*3600)

        ! Process the date part
        call UnpackDate(iJulianDay, iYear, iMonth, iDay)

        ! Extract time from the time part
        iSecond = mod(iTimeSeconds,60)
        iTimeSeconds = iTimeSeconds/60
        iMinute = mod(iTimeSeconds,60)
        iHour   = iTimeSeconds/60

    end subroutine UnpackTime


	! Fractional Julian day, according to NOAA conventions
	function calcJD(year, month, day) result(jd)

		! Routine arguments
		integer, intent(in)	:: year, month, day
		real				:: jd

		! Locals
		integer	:: A
		integer	:: B
		integer	:: yy
		integer	:: mm

		! Compute the Julian day corresponding to passed date
		yy = year
		mm = month
		if(mm <= 2) then
			yy = yy - 1
			mm = mm + 12
		end if
		A = yy/100
		B = 2 - A + A/4
		jd = FLOOR(365.25*(yy + 4716)) + FLOOR(30.6001*(mm+1)) + day + B - 1524.5

	end function calcJD


	! Convert between Julian day and Julian century (unit
	! of common use in astronomy)
	function calcTimeJulianCent(jd) result(T)

		! Routine arguments
		real, intent(in)	:: jd
		real				:: T

		! Locals
		! -none-

		! Compute the Julian century
		T = (jd - 2451545.0)/36525.0

	end function calcTimeJulianCent


	function SunRiseSunSet(yy, mo, dy, lat, lon, zone) result(sunRiseSet)

		implicit none

		! Routine arguments
		integer, intent(in)	:: yy, mo, dy
		real, intent(in)	:: lat, lon
		integer, intent(in)	:: zone
		real, dimension(2)	:: sunRiseSet

		! Locals
		integer	:: iDayOfYear
		real	:: solarDeclination
		real	:: t, b, Sc
		real	:: centralMeridianLongitude
		real	:: localLongitude
		real	:: omegaZeroElev, tZeroElev1, tZeroElev2

		! Parameters
		real, parameter	:: PI = 3.1415927

		! Compute solar declination
		iDayOfYear = DoY(yy,mo,dy)
		solarDeclination = 0.409*SIN(2*PI/365*iDayOfYear - 1.39)

		! Calculate geographical positioning parameters (with a "-" sign for longitudes, according to ASCE conventions)
		centralMeridianLongitude = -zone*15.0
		if(centralMeridianLongitude < 0.0) then
			centralMeridianLongitude = centralMeridianLongitude + 360.0
		end if
		localLongitude = -lon
		if(localLongitude < 0.0) then
			localLongitude = localLongitude + 360.0
		end if

		! Calculate seasonal correction for solar time
		b  = 2.*PI*(iDayOfYear-81)/364.0
		Sc = 0.1645*SIN(2.0*b) - 0.1255*COS(b) - 0.025*SIN(b)

		! Sunrise and sunset angles
		omegaZeroElev = ACOS(-TAN(lat*PI/180.0)*TAN(solarDeclination))
		tZeroElev1 =  omegaZeroElev * 12 / PI + 12.0 - Sc - 0.06667*(centralMeridianLongitude - localLongitude)
		if(tZeroElev1 < 0.) tZeroElev1 = tZeroElev1 + 12.0
		tZeroElev2 = -omegaZeroElev * 12 / PI + 12.0 - Sc - 0.06667*(centralMeridianLongitude - localLongitude)
		if(tZeroElev2 < 0.) tZeroElev2 = tZeroElev2 + 12.0
		sunRiseSet(1) = MIN(tZeroElev1, tZeroElev2)
		sunRiseSet(2) = MAX(tZeroElev1, tZeroElev2)

	end function SunRiseSunSet


	function SinSolarElevation(yy, mo, dy, hh, mm, ss, lat, lon, zone, averagingPeriod) result(sinBeta)

		implicit none

		! Routine arguments
		integer, intent(in)	:: yy, mo, dy, hh, mm, ss
		real, intent(in)	:: lat, lon
		integer, intent(in)	:: zone
		integer, intent(in)	:: averagingPeriod
		real				:: sinBeta

		! Locals
		integer	:: iDayOfYear
		real	:: solarDeclination
		real	:: t, b, Sc
		real	:: centralMeridianLongitude
		real	:: localLongitude
		real	:: omega

		! Parameters
		real, parameter	:: PI = 3.1415927

		! Compute solar declination
		iDayOfYear = DoY(yy,mo,dy)
		solarDeclination = 0.409*SIN(2*PI/365*iDayOfYear - 1.39)

		! Compute current hour at mid of averaging period
		t = hh + mm/60.0 + ss/3600.0 + 0.5 * averagingPeriod / 3600.0

		! Calculate geographical positioning parameters (with a "-" sign for longitudes, according to ASCE conventions)
		centralMeridianLongitude = -zone*15.0
		if(centralMeridianLongitude < 0.0) then
			centralMeridianLongitude = centralMeridianLongitude + 360.0
		end if
		localLongitude = -lon
		if(localLongitude < 0.0) then
			localLongitude = localLongitude + 360.0
		end if

		! Calculate seasonal correction for solar time
		b  = 2.*PI*(iDayOfYear-81)/364.0
		Sc = 0.1645*SIN(2.0*b) - 0.1255*COS(b) - 0.025*SIN(b)

		! Solar time angle at midpoint of averaging time
		omega = (PI/12.0) * ((t + 0.06667*(centralMeridianLongitude - localLongitude) + Sc) - 12.0)

		! Sine of solar elevation angle
		sinBeta = SIN(lat*PI/180.0)*SIN(solarDeclination) + COS(lat*PI/180.0)*COS(solarDeclination)*COS(omega)

	end function SinSolarElevation


	function SolarDeclination(yy, mo, dy) result(sunDecl)

		implicit none

		! Routine arguments
		integer, intent(in)	:: yy, mo, dy
		real				:: sunDecl

		! Locals
		integer	:: iDayOfYear

		! Parameters
		real, parameter	:: PI = 3.1415927

		! Compute solar declination
		iDayOfYear = DoY(yy,mo,dy)
		sunDecl = 0.409*SIN(2.*PI/365.*iDayOfYear - 1.39)

	end function SolarDeclination

	! **************************************
	! * Member functions of DateTime class *
	! **************************************

    subroutine UnpackDate8(iJulianDay, iYear, iMonth, iDay)

        ! Routine arguments
        integer(8), intent(in)     :: iJulianDay
        integer, intent(out)       :: iYear
        integer, intent(out)       :: iMonth
        integer, intent(out)       :: iDay

        ! Locals
        integer(8) :: iDeviation
        integer(8) :: iPreJulianDay
        integer(8) :: iPostJulianDay
        integer(8) :: iYearIndex
        integer(8) :: iMonthIndex
        integer(8) :: iDayIndex
        integer(8), parameter  :: LIMIT_JULIAN_DAY = 2299161
        integer(8), parameter  :: CORRECTION_DAYS  = 1524

        ! Unwind Pope Gregorius' day correction
        if(iJulianDay >= LIMIT_JULIAN_DAY) then
            iDeviation = floor(((iJulianDay-1867216_8)-0.25d0)/36524.25d0, kind=8)
            iPreJulianDay = iJulianDay + iDeviation - iDeviation/4_8 + 1_8
        else
            iPreJulianDay = iJulianDay
        end if
        iPostJulianDay = iPreJulianDay + CORRECTION_DAYS

        ! Compute time indices
        iYearIndex  = floor(6680_8+((iPostJulianDay-2439870_8)-122.1d0)/YEAR_DURATION, kind=8)
        iDayIndex   = 365_8*iYearIndex + iYearIndex/4_8
        iMonthIndex = floor((iPostJulianDay - iDayIndex)/MONTH_DURATION, kind=8)

        ! Deduce preliminary date from time indices
        iDay = iPostJulianDay - floor(MONTH_DURATION*iMonthIndex, kind=8	) - iDayIndex
        if(iMonthIndex > 13_8) then
            iMonth = iMonthIndex - 13_8
        else
            iMonth = iMonthIndex - 1_8
        end if
        iYear = iYearIndex - 4715_8
        if(iMonth > 2) iYear = iYear - 1

    end subroutine UnpackDate8


    function dtFromEpoch(this, rEpoch) result(iRetCode)

        ! Routine arguments
        class(DateTime), intent(out)	:: this
        real(8), intent(in)				:: rEpoch
        integer							:: iRetCode

        ! Locals
        integer(8)	:: iJulianDay
        real(8) 	:: rTimeSeconds

        ! Assume success (will falsify on failure)
        iRetCode = 0

        ! Check parameter
        if(rEpoch < TIME_MIN .or. rEpoch >= TIME_MAX) then
			iRetCode = 1
			this % iYear   = 1970
			this % iMonth  = 1
			this % iDay    = 1
			this % iHour   = 0
			this % iMinute = 0
			this % rSecond = 0.d0
            return
        elseif(.invalid.rEpoch) then
			iRetCode = 1
			this % iYear   = 1970
			this % iMonth  = 1
			this % iDay    = 1
			this % iHour   = 0
			this % iMinute = 0
			this % rSecond = 0.d0
            return
        end if

        ! Isolate the date and time parts
        iJulianDay = floor(rEpoch/(24.d0*3600.d0), kind=8) + BASE_DAY_8
        rTimeSeconds = mod(rEpoch, 24.d0*3600.d0)

        ! Process the date part
        call UnpackDate8(iJulianDay, this % iYear, this % iMonth, this % iDay)

        ! Extract time from the time part
        this % rSecond = mod(rTimeSeconds,60.d0)
        rTimeSeconds = rTimeSeconds/60.d0
        this % iMinute = mod(floor(rTimeSeconds, kind=8),60_8)
        this % iHour   = floor(rTimeSeconds, kind=8)/60_8

    end function dtFromEpoch


    function dtToEpoch(this, iClipping) result(rEpoch)

        ! Routine arguments
        class(DateTime), intent(in)		:: this
        integer, intent(in), optional	:: iClipping
        real(8)							:: rEpoch

        ! Locals
        integer    :: iJulianDay
        integer(8) :: iJulianSecond
        integer    :: iClip

        ! Check input parameters for validity
        if(.not. (.sensible. this)) then
            rEpoch = NaN_8
            return
        end if
        if(present(iClipping)) then
        	if(iClipping < CLP_YEAR .or. iClipping > CLP_SECOND) then
        		rEpoch = NaN_8
        		return
        	end if
        	iClip = iClipping
        else
        	iClip = 0
        end if

        ! Dispatch processing
        select case(iClip)
        case(0)	! No clipping (default)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, this % iMonth, this % iDay) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond + this % rSecond + 60_4*(this % iMinute + 60_4*this % iHour)

        case(CLP_YEAR)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, 1, 1) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond

        case(CLP_MONTH)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, this % iMonth, 1) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond

        case(CLP_DAY)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, this % iMonth, this % iDay) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond

        case(CLP_HOUR)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, this % iMonth, this % iDay) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond + 60_4*(60_4*this % iHour)

        case(CLP_MINUTE)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, this % iMonth, this % iDay) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond + 60_4*(this % iMinute + 60_4*this % iHour)

        case(CLP_SECOND)

	        ! Compute based Julian day
	        iJulianDay = JulianDay(this % iYear, this % iMonth, this % iDay) - BASE_DAY

	        ! Convert based Julian day to second, and add seconds from time,
	        ! regardless of hour type.
	        iJulianSecond = iJulianDay * 24_8 * 3600_8
	        rEpoch = iJulianSecond + int(this % rSecond, kind=8) + 60_4*(this % iMinute + 60_4*this % iHour)

        end select

    end function dtToEpoch


    function dtToIso(this) result(sDateTime)

		! Routine arguments
		class(DateTime), intent(in)	:: this
		character(len=23)			:: sDateTime

		! Locals
		integer	:: iSecond
		real(8)	:: rSubSecond

		! Write the data desired
		iSecond = floor(this % rSecond)
		rSubSecond = this % rSecond - iSecond
		write(sDateTime, "(i4.4,2('-',i2.2),1x,i2.2,2(':',i2.2),f4.3)") &
			this % iYear, &
			this % iMonth, &
			this % iDay, &
			this % iHour, &
			this % iMinute, &
			iSecond, rSubSecond

    end function dtToIso


    function dtSunRiseSet(this, rLat, rLon, iZone, rSunRise, rSunSet) result(iRetCode)

		! Routine arguments
		class(DateTime), intent(in)	:: this
		real, intent(in)			:: rLat
		real, intent(in)			:: rLon
		integer, intent(in)			:: iZone
		real(8), intent(out)		:: rSunRise
		real(8), intent(out)		:: rSunSet
		integer						:: iRetCode

		! Locals
		real, dimension(2)	:: rvSunRiseSet

		! Assume success (will falsify on failure)
		iRetCode = 0

        ! Check input parameters for validity
        if(.not. (.sensible. this)) then
            rSunRise = NaN_8
            rSunSet  = NaN_8
            iRetCode = 1
            return
        end if

		! Compute sunrise and sunset times
		rvSunRiseSet = SunRiseSunSet(this % iYear, this % iMonth, this % iDay, rLat, rLon, iZone)

		! Dispatch results
		rSunRise = rvSunRiseSet(1)
		rSunSet  = rvSunRiseSet(2)

    end function dtSunRiseSet

	! *********************
	! * Internal routines *
	! *********************

	function timeEncode1(rvTimeStamp, iPeriodLength, iStepSize, ivTimeCode) result(iRetCode)

		! Routine arguments
		real(8), intent(in), dimension(:)				:: rvTimeStamp
		integer, intent(in)								:: iPeriodLength
		integer, intent(in)								:: iStepSize
		integer, intent(out), dimension(:), allocatable	:: ivTimeCode
		integer											:: iRetCode

		! Locals
		integer		:: n
		integer		:: i
		integer(8)	:: iTimeStamp

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivTimeCode)) deallocate(ivTimeCode)
		n = size(rvTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivTimeCode(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(.valid.rvTimeStamp(i)) then
				iTimeStamp = floor(rvTimeStamp(i), kind=8)
				ivTimeCode(i) = mod(iTimeStamp, iPeriodLength) / iStepSize + 1
			else
				ivTimeCode(i) = 0	! Special "invalid" code
			end if
		end do

	end function timeEncode1


	function timeEncode2(ivTimeStamp, iPeriodLength, iStepSize, ivTimeCode) result(iRetCode)

		! Routine arguments
		integer, intent(in), dimension(:)				:: ivTimeStamp
		integer, intent(in)								:: iPeriodLength
		integer, intent(in)								:: iStepSize
		integer, intent(out), dimension(:), allocatable	:: ivTimeCode
		integer											:: iRetCode

		! Locals
		integer		:: n
		integer		:: i

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivTimeCode)) deallocate(ivTimeCode)
		n = size(ivTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivTimeCode(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(ivTimeStamp(i) > 0) then
				ivTimeCode(i) = mod(ivTimeStamp(i), iPeriodLength) / iStepSize + 1
			else
				ivTimeCode(i) = 0	! Special "invalid" code
			end if
		end do

	end function timeEncode2


	function timeLinearIndex1(rvTimeStamp, iStepSize, ivTimeCode, rvBaseTimeStamp) result(iRetCode)

		! Routine arguments
		real(8), intent(in), dimension(:)							:: rvTimeStamp
		integer, intent(in)											:: iStepSize
		integer, intent(out), dimension(:), allocatable				:: ivTimeCode
		real(8), intent(out), dimension(:), allocatable, optional	:: rvBaseTimeStamp
		integer														:: iRetCode

		! Locals
		integer		:: n
		integer		:: i
		integer(8)	:: iTimeStamp

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivTimeCode)) deallocate(ivTimeCode)
		n = size(rvTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivTimeCode(n))
		if(present(rvBaseTimeStamp)) then
			if(allocated(rvBaseTimeStamp)) deallocate(rvBaseTimeStamp)
			allocate(rvBaseTimeStamp(n))
		end if

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(.valid.rvTimeStamp(i)) then
				iTimeStamp = floor(rvTimeStamp(i), kind=8)
				ivTimeCode(i) = iTimeStamp / iStepSize + 1
			else
				ivTimeCode(i) = 0	! Special "invalid" code
			end if
		end do
		if(present(rvBaseTimeStamp)) then
			where(ivTimeCode > 0)
				rvBaseTimeStamp = int(ivTimeCode-1, kind=8) * iStepSize
			elsewhere
				rvBaseTimeStamp = NaN_8
			endwhere
		end if
		where(ivTimeCode > 0)
			ivTimeCode = ivTimeCode - minval(ivTimeCode, mask=ivTimeCode > 0) + 1
		end where

	end function timeLinearIndex1


	function timeLinearIndex2(ivTimeStamp, iStepSize, ivTimeCode, ivBaseTimeStamp) result(iRetCode)

		! Routine arguments
		integer, intent(in), dimension(:)							:: ivTimeStamp
		integer, intent(in)											:: iStepSize
		integer, intent(out), dimension(:), allocatable				:: ivTimeCode
		integer, intent(out), dimension(:), allocatable, optional	:: ivBaseTimeStamp
		integer														:: iRetCode

		! Locals
		integer		:: n
		integer		:: i

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivTimeCode)) deallocate(ivTimeCode)
		n = size(ivTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivTimeCode(n))
		if(present(ivBaseTimeStamp)) then
			if(allocated(ivBaseTimeStamp)) deallocate(ivBaseTimeStamp)
			allocate(ivBaseTimeStamp(n))
		end if

		do i = 1, n
			if(ivTimeStamp(i) > 0) then
				ivTimeCode(i) = ivTimeStamp(i) / iStepSize + 1
			else
				ivTimeCode(i) = 0	! Special "invalid" code
			end if
		end do
		if(present(ivBaseTimeStamp)) then
			where(ivTimeCode > 0)
				ivBaseTimeStamp = (ivTimeCode-1) * iStepSize
			elsewhere
				ivBaseTimeStamp = 0
			endwhere
		end if
		where(ivTimeCode > 0)
			ivTimeCode = ivTimeCode - minval(ivTimeCode, mask=ivTimeCode > 0) + 1
		end where

	end function timeLinearIndex2


	function timeGetYear1(rvTimeStamp, ivYear) result(iRetCode)

		! Routine arguments
		real(8), intent(in), dimension(:)				:: rvTimeStamp
		integer, intent(out), dimension(:), allocatable	:: ivYear
		integer											:: iRetCode

		! Locals
		integer			:: n
		integer			:: i
		type(DateTime)	:: dt
		integer			:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivYear)) deallocate(ivYear)
		n = size(rvTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivYear(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(.valid.rvTimeStamp(i)) then
				iErrCode = dt % fromEpoch(rvTimeStamp(i))
				if(iErrCode == 0) then
					ivYear(i) = dt % iYear
				else
					ivYear(i) = -9999	! Special "invalid" code
				end if
			else
				ivYear(i) = -9999	! Special "invalid" code
			end if
		end do

	end function timeGetYear1


	function timeGetYear2(ivTimeStamp, ivYear) result(iRetCode)

		! Routine arguments
		integer, intent(in), dimension(:)				:: ivTimeStamp
		integer, intent(out), dimension(:), allocatable	:: ivYear
		integer											:: iRetCode

		! Locals
		integer		:: n
		integer		:: i
		integer		:: iYear, iMonth, iDay, iHour, iMinute, iSecond

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivYear)) deallocate(ivYear)
		n = size(ivTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivYear(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(ivTimeStamp(i) > 0) then
				call UnpackTime(ivTimeStamp(i), iYear, iMonth, iDay, iHour, iMinute, iSecond)
				ivYear(i) = iYear
			else
				ivYear(i) = -9999	! Special "invalid" code
			end if
		end do

	end function timeGetYear2


	function timeGetMonth1(rvTimeStamp, ivMonth) result(iRetCode)

		! Routine arguments
		real(8), intent(in), dimension(:)				:: rvTimeStamp
		integer, intent(out), dimension(:), allocatable	:: ivMonth
		integer											:: iRetCode

		! Locals
		integer			:: n
		integer			:: i
		type(DateTime)	:: dt
		integer			:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivMonth)) deallocate(ivMonth)
		n = size(rvTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivMonth(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(.valid.rvTimeStamp(i)) then
				iErrCode = dt % fromEpoch(rvTimeStamp(i))
				if(iErrCode == 0) then
					ivMonth(i) = dt % iMonth
				else
					ivMonth(i) = -9999	! Special "invalid" code
				end if
			else
				ivMonth(i) = -9999	! Special "invalid" code
			end if
		end do

	end function timeGetMonth1


	function timeGetMonth2(ivTimeStamp, ivMonth) result(iRetCode)

		! Routine arguments
		integer, intent(in), dimension(:)				:: ivTimeStamp
		integer, intent(out), dimension(:), allocatable	:: ivMonth
		integer											:: iRetCode

		! Locals
		integer		:: n
		integer		:: i
		integer		:: iYear, iMonth, iDay, iHour, iMinute, iSecond

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivMonth)) deallocate(ivMonth)
		n = size(ivTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivMonth(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(ivTimeStamp(i) > 0) then
				call UnpackTime(ivTimeStamp(i), iYear, iMonth, iDay, iHour, iMinute, iSecond)
				ivMonth(i) = iMonth
			else
				ivMonth(i) = -9999	! Special "invalid" code
			end if
		end do

	end function timeGetMonth2


	function timeGetYearMonth1(rvTimeStamp, ivYearMonth) result(iRetCode)

		! Routine arguments
		real(8), intent(in), dimension(:)				:: rvTimeStamp
		integer, intent(out), dimension(:), allocatable	:: ivYearMonth
		integer											:: iRetCode

		! Locals
		integer			:: n
		integer			:: i
		type(DateTime)	:: dt
		integer			:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivYearMonth)) deallocate(ivYearMonth)
		n = size(rvTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivYearMonth(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(.valid.rvTimeStamp(i)) then
				iErrCode = dt % fromEpoch(rvTimeStamp(i))
				if(iErrCode == 0) then
					ivYearMonth(i) = 12 * dt % iYear + dt % iMonth - 1
				else
					ivYearMonth(i) = -9999	! Special "invalid" code
				end if
			else
				ivYearMonth(i) = -9999	! Special "invalid" code
			end if
		end do

	end function timeGetYearMonth1


	function timeGetYearMonth2(ivTimeStamp, ivYearMonth) result(iRetCode)

		! Routine arguments
		integer, intent(in), dimension(:)				:: ivTimeStamp
		integer, intent(out), dimension(:), allocatable	:: ivYearMonth
		integer											:: iRetCode

		! Locals
		integer		:: n
		integer		:: i
		integer		:: iYear, iMonth, iDay, iHour, iMinute, iSecond

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace
		if(allocated(ivYearMonth)) deallocate(ivYearMonth)
		n = size(ivTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		allocate(ivYearMonth(n))

		! Iterate over time stamps, and assign codes
		do i = 1, n
			if(ivTimeStamp(i) > 0) then
				call UnpackTime(ivTimeStamp(i), iYear, iMonth, iDay, iHour, iMinute, iSecond)
				ivYearMonth(i) = 12 * iYear + iMonth - 1
			else
				ivYearMonth(i) = -9999	! Special "invalid" code
			end if
		end do

	end function timeGetYearMonth2


	function timeSequence1(rTimeFrom, rTimeTo, iTimeStep, lRightInclusive, rvTimeStamp) result(iRetCode)

		! Routine arguments
		real(8), intent(in)								:: rTimeFrom
		real(8), intent(in)								:: rTimeTo
		integer, intent(in)								:: iTimeStep
		logical, intent(in), optional					:: lRightInclusive
		real(8), intent(out), dimension(:), allocatable	:: rvTimeStamp
		integer											:: iRetCode

		! Locals
		integer		:: n
		real(8)		:: rCurTime
		integer		:: j
		logical		:: lInclude

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Set upper limit for time
		if(present(lRightInclusive)) then
			lInclude = lRightInclusive
		else
			lInclude = .false.
		end if

		! Check parameters
		if(rTimeFrom > rTimeTo .and. lInclude) then
			iRetCode = 1
			return
		elseif(rTimeFrom >= rTimeTo .and. .not.lInclude) then
			iRetCode = 1
			return
		end if

		! Compute size of time stamp vector
		n = 0
		rCurTime = rTimeFrom
		if(lInclude) then
			do while(rCurTime <= rTimeTo)
				n = n + 1
				rCurTime = rCurTime + iTimeStep
			end do
		else
			do while(rCurTime < rTimeTo)
				n = n + 1
				rCurTime = rCurTime + iTimeStep
			end do
		end if
		if(n <= 0) then
			! This should really never happen, given tests made on time limits. But, it
			! costs nothing adding it, as a defensive programming technique.
			iRetCode = 2
		end if
		! The vector of date-times is guaranteed to be non-empty from now on.

		! Reserve workspace
		if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
		allocate(rvTimeStamp(n))

		! Generate time stamps sequence
		j = 0
		rCurTime = rTimeFrom
		if(lInclude) then
			do while(rCurTime <= rTimeTo)
				j = j + 1
				rvTimeStamp(j) = rCurTime
				rCurTime = rCurTime + iTimeStep
			end do
		else
			do while(rCurTime < rTimeTo)
				j = j + 1
				rvTimeStamp(j) = rCurTime
				rCurTime = rCurTime + iTimeStep
			end do
		end if

	end function timeSequence1


	function timeSequence2(iTimeFrom, iTimeTo, iTimeStep, lRightInclusive, ivTimeStamp) result(iRetCode)

		! Routine arguments
		integer, intent(in)								:: iTimeFrom
		integer, intent(in)								:: iTimeTo
		integer, intent(in)								:: iTimeStep
		logical, intent(in), optional					:: lRightInclusive
		integer, intent(out), dimension(:), allocatable	:: ivTimeStamp
		integer											:: iRetCode

		! Locals
		integer		:: n
		integer		:: i
		integer		:: j
		logical		:: lInclude
		integer		:: iCurTime

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Set upper limit for time
		if(present(lRightInclusive)) then
			lInclude = lRightInclusive
		else
			lInclude = .false.
		end if

		! Check parameters
		if(iTimeFrom > iTimeTo .and. lInclude) then
			iRetCode = 1
			return
		elseif(iTimeFrom >= iTimeTo .and. .not.lInclude) then
			iRetCode = 1
			return
		end if

		! Compute size of time stamp vector
		n = 0
		iCurTime = iTimeFrom
		if(lInclude) then
			do while(iCurTime <= iTimeTo)
				n = n + 1
				iCurTime = iCurTime + iTimeStep
			end do
		else
			do while(iCurTime < iTimeTo)
				n = n + 1
				iCurTime = iCurTime + iTimeStep
			end do
		end if
		if(n <= 0) then
			! This should really never happen, given tests made on time limits. But, it
			! costs nothing adding it, as a defensive programming technique.
			iRetCode = 2
		end if
		! The vector of date-times is guaranteed to be non-empty from now on.

		! Reserve workspace
		if(allocated(ivTimeStamp)) deallocate(ivTimeStamp)
		allocate(ivTimeStamp(n))

		! Generate time stamps sequence
		j = 0
		iCurTime = iTimeFrom
		if(lInclude) then
			do while(iCurTime <= iTimeTo)
				j = j + 1
				ivTimeStamp(j) = iCurTime
				iCurTime = iCurTime + iTimeStep
			end do
		else
			do while(iCurTime < iTimeTo)
				j = j + 1
				ivTimeStamp(j) = iCurTime
				iCurTime = iCurTime + iTimeStep
			end do
		end if

	end function timeSequence2


	function timeFloorDay1(iTimeStamp) result(iDayStamp)

		! Routine arguments
		integer, intent(in)	:: iTimeStamp
		integer				:: iDayStamp

		! Locals
		! -none-

		! Constants
		integer, parameter	:: ONE_DAY = 3600*24

		! Compute the desired quantity
		iDayStamp = iTimeStamp - mod(iTimeStamp, ONE_DAY)

	end function timeFloorDay1


	function timeFloorDay2(rTimeStamp) result(rDayStamp)

		! Routine arguments
		real(8), intent(in)	:: rTimeStamp
		real(8)				:: rDayStamp

		! Locals
		! -none-

		! Constants
		real(8), parameter	:: ONE_DAY = 3600.d0*24

		! Compute the desired quantity
		rDayStamp = floor(rTimeStamp/ONE_DAY) * ONE_DAY

	end function timeFloorDay2


	function timeCeilingDay1(iTimeStamp) result(iDayStamp)

		! Routine arguments
		integer, intent(in)	:: iTimeStamp
		integer				:: iDayStamp

		! Locals
		integer	:: iTemporary

		! Constants
		integer, parameter	:: ONE_DAY = 3600*24

		! Compute the desired quantity
		iTemporary = mod(iTimeStamp, ONE_DAY)
		if(iTemporary /= 0) then
			iDayStamp = iTimeStamp - iTemporary
		else
			iDayStamp = iTimeStamp
		end if

	end function timeCeilingDay1


	function timeCeilingDay2(rTimeStamp) result(rDayStamp)

		! Routine arguments
		real(8), intent(in)	:: rTimeStamp
		real(8)				:: rDayStamp

		! Locals
		! -none-

		! Constants
		real(8), parameter	:: ONE_DAY = 3600.d0*24

		! Compute the desired quantity
		rDayStamp = ceiling(rTimeStamp/ONE_DAY) * ONE_DAY

	end function timeCeilingDay2


	function timeFloorHour1(iTimeStamp) result(iHourStamp)

		! Routine arguments
		integer, intent(in)	:: iTimeStamp
		integer				:: iHourStamp

		! Locals
		! -none-

		! Constants
		integer, parameter	:: ONE_HOUR = 3600

		! Compute the desired quantity
		iHourStamp = iTimeStamp - mod(iTimeStamp, ONE_HOUR)

	end function timeFloorHour1


	function timeFloorHour2(rTimeStamp) result(rHourStamp)

		! Routine arguments
		real(8), intent(in)	:: rTimeStamp
		real(8)				:: rHourStamp

		! Locals
		! -none-

		! Constants
		real(8), parameter	:: ONE_HOUR = 3600.d0

		! Compute the desired quantity
		rHourStamp = floor(rTimeStamp/ONE_HOUR) * ONE_HOUR

	end function timeFloorHour2


	function timeCeilingHour1(iTimeStamp) result(iHourStamp)

		! Routine arguments
		integer, intent(in)	:: iTimeStamp
		integer				:: iHourStamp

		! Locals
		integer	:: iTemporary

		! Constants
		integer, parameter	:: ONE_HOUR = 3600

		! Compute the desired quantity
		iTemporary = mod(iTimeStamp, ONE_HOUR)
		if(iTemporary /= 0) then
			iHourStamp = iTimeStamp - iTemporary
		else
			iHourStamp = iTimeStamp
		end if

	end function timeCeilingHour1


	function timeCeilingHour2(rTimeStamp) result(rHourStamp)

		! Routine arguments
		real(8), intent(in)	:: rTimeStamp
		real(8)				:: rHourStamp

		! Locals
		! -none-

		! Constants
		real(8), parameter	:: ONE_HOUR = 3600.d0

		! Compute the desired quantity
		rHourStamp = ceiling(rTimeStamp/ONE_HOUR) * ONE_HOUR

	end function timeCeilingHour2


	function isSensible(tDateTime) result(lIsSensible)

		! Routine arguments
		type(DateTime), intent(in)	:: tDateTime
		logical						:: lIsSensible

		! Locals
		! --none--

		! Compute the information desired
        lIsSensible = .not.( &
            tDateTime % iYear   <= 0   .or. &
            tDateTime % iMonth  < 1    .or. tDateTime % iMonth  >  12 .OR. &
            tDateTime % iDay    < 1    .or. tDateTime % iDay    >  31 .OR. &
            tDateTime % iHour   < 0    .or. tDateTime % iHour   >  23 .OR. &
            tDateTime % iMinute < 0    .or. tDateTime % iMinute >  59 .OR. &
            tDateTime % rSecond < 0.d0 .or. tDateTime % rSecond >= 60.d0 &
		)

	end function isSensible

end module pbl_time


! pbl_stat  : Fortran module, providing support to elementary statistics.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_stat

    use ieee_arithmetic
    use pbl_base
    use pbl_time

    implicit none

    private

    ! Public interface
    ! 1. Off-range and invalid data management
    public	:: RangeInvalidate
    public	:: PairInvalidate
    public	:: RangeClip
    public	:: GetValidOnly
    ! 2. Basic statistics
    public	:: Mean
    public	:: StdDev
    public  :: Cov
    public	:: Quantile
    public	:: Skew
    public	:: Kurt
    ! 3. Autocovariance, autocorrelation and related
    public	:: AutoCov
    public	:: AutoCorr
    public	:: PartialAutoCorr
    public	:: EulerianTime
    ! 4. Cross-covariance, cross-correlation and related
    public	:: CrossCov
    public	:: CrossCorr
    ! 5. Peak detection
    ! 6. Utilities
    public	:: RemoveLinearTrend
    ! 7. Time series
    public	:: TimeSeries
    public	:: TDELTA_YEAR
    public	:: TDELTA_MONTH
    public	:: TDELTA_YEARMONTH
    public	:: TDELTA_ONEMINUTE
    public	:: TDELTA_ONEHOUR
    public	:: TDELTA_ONEDAY
    public	:: FUN_MEAN
    public	:: FUN_STDEV
    public	:: FUN_MIN
    public	:: FUN_MAX
    public	:: QUANT_POPULATION	! Population quantile
    public	:: QUANT_1			! Sample quantile type 1 (R-1, SAS-3, Maple-1; inverse of edf)
    public	:: QUANT_2			! Sample quantile type 2 (R-2, SAS-5, Maple-2; same as R-1, with averaging at discontinuities)
    public	:: QUANT_3			! Sample quantile type 3 (R-3, Closest observation)
    public	:: QUANT_3_R		! Synonym of QUANT_3
    public	:: QUANT_3_SAS		! Sample quantile type 3 (SAS-2; Closest observation, but with an own definition of "closest integer")
    public	:: QUANT_4			! Sample quantile type 4 (R-4, SAS-1, Maple-3; Linear interpolation of edf)
    public	:: QUANT_5			! Sample quantile type 5 (R-5, Maple-4; piecewise linear function with nodes at midway of edf values)
    public	:: QUANT_6			! Sample quantile type 6 (R-6, SAS-4, Maple-5, Excel; Linear interpolation of order statistics for uniform distribution on [0,1])
    public	:: QUANT_7			! Sample quantile type 7 (R-7, Maple-6, Excel, NumPy; Linear interpolation of the modes of the order statistics for uniform distribution on [0,1])
    public	:: QUANT_8			! Sample quantile type 8 (R-8, Maple-7; ***DEFAULT***; Linear interpolation of approximate medians of order statistics; Distribution-independent)
    public	:: QUANT_9			! Sample quantile type 9 (R-9, Maple-8; Defined so that the resulting quantile estimates are approximately unbiased for the expected order statistics; Valid if data are normally distributed)
    public	:: MA_ALLDATA		! Use all available data when computing centered moving averages
    public	:: MA_STRICT		! Discard incomplete upper and lower time tails when computing centered moving averages

    ! Data types

    type TimeSeries
    	real(8), dimension(:), allocatable, private	:: rvTimeStamp
    	real, dimension(:), allocatable, private	:: rvValue
    contains
    	! Constructors
    	procedure, public	:: createEmpty						=> tsCreateEmpty
    	procedure, public	:: createFromTimeSeries				=> tsCreateFromTimeSeries
    	procedure, public	:: createFromDataVector				=> tsCreateFromDataVector
    	procedure, public	:: createFromTimeAndDataVectors		=> tsCreateFromTimeAndDataVectors
    	! Modifiers and reshapers
    	procedure, public	:: populateFromDataVector			=> tsCreateFromDataVector
    	procedure, public	:: populateFromTimeAndDataVectors	=> tsCreateFromTimeAndDataVectors
    	procedure, public	:: rangeInvalidate					=> tsRangeInvalidate
    	procedure, public	:: timeShift						=> tsTimeShift
    	procedure, public	:: timeReorder						=> tsTimeReorder
    	! Selectors
    	procedure, public	:: getSingleItem					=> tsGetSingleItem
    	procedure, public	:: getTimeStamp						=> tsGetTimeStamp
    	procedure, public	:: getValues						=> tsGetValues
    	procedure, public	:: getTimeSubset					=> tsGetTimeSubset
    	procedure, public	:: getMonth							=> tsGetMonth
    	! Assigners
    	procedure, public	:: putSingleItem					=> tsPutSingleItem
    	! Summary generators
    	procedure, public	:: size								=> tsSize
    	procedure, public	:: isSameTimes						=> tsIsSameTimes
    	procedure, public	:: summary							=> tsSummary
    	procedure, public	:: getTimeSpan						=> tsGetTimeSpan
    	! State interrogations
    	procedure, public	:: isEmpty							=> tsIsEmpty
    	procedure, public	:: timeIsMonotonic					=> tsTimeMonotonic
    	procedure, public	:: timeIsQuasiMonotonic				=> tsTimeQuasiMonotonic
    	procedure, public	:: timeIsGapless					=> tsTimeGapless
    	procedure, public	:: timeIsWellSpaced					=> tsTimeWellSpaced
    	! Aggregators
    	procedure, public	:: aggregateLinear					=> tsAggregateLinear
    	procedure, public	:: aggregateLinear2					=> tsAggregateLinear2
    	procedure, public	:: aggregatePeriodic				=> tsAggregatePeriodic
    	! Smoothers
    	procedure, public	:: movingAverage					=> tsMovingAverage
    	procedure, public	:: movingStdDev						=> tsMovingStdDev
    	! Gap fillers
    	procedure, public	:: fillGaps							=> tsFillGaps
    end type TimeSeries


	type TwoDimensionalField
		real(8), dimension(:,:), allocatable	:: rmValue
		real(8), dimension(:), allocatable		:: rvX
		real(8), dimension(:), allocatable		:: rvY
		integer, dimension(:,:), allocatable	:: imNumAdjacent
		integer, dimension(:,:,:), allocatable	:: iaAdjacent
		real(8), dimension(:,:,:), allocatable	:: raDistance
	contains
		procedure, public	:: clean				=> dfClean
		procedure, public	:: initialize			=> dfInitialize
		procedure, public	:: evaluate				=> dfEvaluate
	end type TwoDimensionalField

    ! Constants

    integer, parameter	:: TDELTA_YEARMONTH  =    -3
    integer, parameter	:: TDELTA_YEAR       =    -2
    integer, parameter	:: TDELTA_MONTH      =    -1
    integer, parameter	:: TDELTA_ONEMINUTE  =    60
    integer, parameter	:: TDELTA_ONEHOUR    =  3600
    integer, parameter	:: TDELTA_ONEDAY     = 86400
    integer, parameter	:: FUN_MEAN          =     0
    integer, parameter	:: FUN_STDEV         =     1
    integer, parameter	:: FUN_MIN           =     2
    integer, parameter	:: FUN_MAX           =     3
    integer, parameter	:: QUANT_POPULATION  =     0
    integer, parameter	:: QUANT_1           =     1
    integer, parameter	:: QUANT_2           =     2
    integer, parameter	:: QUANT_3           =     3
    integer, parameter	:: QUANT_3_R         =     QUANT_3
    integer, parameter	:: QUANT_3_SAS       =    10
    integer, parameter	:: QUANT_4           =     4
    integer, parameter	:: QUANT_5           =     5
    integer, parameter	:: QUANT_6           =     6
    integer, parameter	:: QUANT_7           =     7
    integer, parameter	:: QUANT_8           =     8
    integer, parameter	:: QUANT_9           =     9
    integer, parameter	:: MA_ALLDATA        =     0
    integer, parameter	:: MA_STRICT         =     1

    ! Polymorphic interfaces

    interface Quantile
    	module procedure	:: QuantileScalar
    	module procedure	:: QuantileVector
    end interface Quantile

contains

	! Make data outside a specified range invalid, by replacing their value with NaN
	subroutine RangeInvalidate(rvX, rMin, rMax)

		! Routine arguments
		real, dimension(:), intent(inout)	:: rvX		! Vector of data to range-invalidate
		real, intent(in)					:: rMin		! Minimum allowed value
		real, intent(in)					:: rMax		! Maximum allowed value

		! Locals
		integer	:: i

		! Validate by range
		do i = 1, size(rvX)
			if(rvX(i) < rMin) then
				rvX(i) = NaN
			elseif(rvX(i) > rMax) then
				rvX(i) = NaN
			end if
		end do

	end subroutine RangeInvalidate


	! Make invalid data in a vector invalid if those of another also are, and viceversa.
	! After
	subroutine PairInvalidate(rvX, rvY)

		! Routine arguments
		real, dimension(:), intent(inout)	:: rvX		! Vector to pair-invalidate
		real, dimension(:), intent(inout)	:: rvY		! Vector to pair-invalidate

		! Locals
		integer	:: i
		integer	:: iMin, iMax

		! Compute loop limits from array dimensions
		iMin = max(lbound(rvX,dim=1), lbound(rvY,dim=1))
		iMax = min(ubound(rvX,dim=1), ubound(rvY,dim=1))

		! Ensure invalid positions in one vector are propagated to the other
		do i = iMin, iMax
			if(.invalid. rvX(i)) then
				rvY(i) = NaN
			elseif(.invalid. rvY(i)) then
				rvX(i) = NaN
			end if
		end do

	end subroutine PairInvalidate


	! Force data to be within a specified range invalid, clipping to extremal values
	subroutine RangeClip(rvX, rMin, rMax)

		! Routine arguments
		real, dimension(:), intent(inout)	:: rvX		! Vector of data to range-clip
		real, intent(in)					:: rMin		! Minimum allowed value
		real, intent(in)					:: rMax		! Maximum allowed value

		! Locals
		integer	:: i

		! Validate by range
		do i = 1, size(rvX)
			if(rvX(i) < rMin) then
				rvX(i) = rMin
			elseif(rvX(i) > rMax) then
				rvX(i) = rMax
			end if
		end do

	end subroutine RangeClip


	! Pack a vector to another vector containing only valid (i.e. non-NaN) data
	function GetValidOnly(rvX) result(rvValidX)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX			! Vector of data containing zero or more NaN
		real, dimension(:), allocatable	:: rvValidX		! The same vector, with all NaN values stripped

		! Locals
		integer	:: iNumValid
		integer	:: i, j

		! Count valid data, and check something is to be made
		iNumValid = count(.not.ieee_is_nan(rvX))
		if(allocated(rvValidX)) deallocate(rvValidX)
		if(size(rvX) <= 0 .or. iNumValid <= 0) then
			allocate(rvValidX(0))
			return
		end if

		! Loop over data, copying valids only to the new vector
		allocate(rvValidX(iNumValid))
		j = 0
		do i = 1, size(rvX)
			if(.not.ieee_is_nan(rvX(i))) then
				j = j + 1
				rvValidX(j) = rvX(i)
			end if
		end do

	end function GetValidOnly


	! Compute the mean of a signal
	function Mean(rvX, rValidFraction) result(rMean)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX				! Signal, whose mean is needed
		real, intent(out), optional		:: rValidFraction	! Fraction of valid to total signal data (optional)
		real							:: rMean			! Mean (NaN if not possible to evaluate)

		! Locals
		integer	:: n

		! Check something is to be made
		if(size(rvX) <= 0) then
			rMean = NaN
			return
		end if

		! Compute the arithmetic mean
		n = count(.not.ieee_is_nan(rvX))
		if(n > 0) then
			rMean = sum(rvX, mask=.not.ieee_is_nan(rvX)) / n
		else
			rMean = NaN
		end if

		! Compute diagnostic quantities, if present
		if(present(rValidFraction)) then
			rValidFraction = float(n) / size(rvX)
		end if

	end function Mean


	! Compute the population standard deviation of a signal
	function StdDev(rvX, rMeanIn, rValidFraction) result(rStdDev)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX				! Signal, whose standard deviation is needed
		real, intent(in), optional		:: rMeanIn			! Mean value, as computed by "Mean" function (optional, recomputed if missing)
		real, intent(out), optional		:: rValidFraction	! Fraction of valid to total signal data (optional)
		real							:: rStdDev

		! Locals
		integer	:: n
		real	:: rMean

		! Check something is to be made
		if(size(rvX) <= 0) then
			rMean = NaN
			return
		end if

		! Compute the arithmetic mean, if missing; or, get its value
		n = count(.not.ieee_is_nan(rvX))
		if(present(rMeanIn)) then
			rMean = rMeanIn
		else
			if(n > 0) then
				rMean = sum(rvX, mask=.not.ieee_is_nan(rvX)) / n
			else
				rMean = NaN
			end if
		end if

		! Compute the standard deviation
		if(n > 0) then
			rStdDev = sqrt(sum((rvX - rMean)**2, mask=.not.ieee_is_nan(rvX)) / n)
		else
			rStdDev = NaN
		end if

		! Compute diagnostic quantities, if present
		if(present(rValidFraction)) then
			rValidFraction = float(n) / size(rvX)
		end if

	end function StdDev


	! Compute the population skewness of a signal
	function Skew(rvX, rMeanIn, rStdDevIn, rValidFraction) result(rSkewness)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX				! Signal, whose skewness is needed
		real, intent(in), optional		:: rMeanIn			! Mean value, as computed by "Mean" function (optional, recomputed if missing)
		real, intent(in), optional		:: rStdDevIn		! Standard deviation, as computed by "StdDev" function (optional, recomputed if missing)
		real, intent(out), optional		:: rValidFraction	! Fraction of valid to total signal data (optional)
		real							:: rSkewness

		! Locals
		integer	:: n
		real	:: rMean
		real	:: rStdDev
		real	:: m3

		! Check something is to be made
		if(size(rvX) <= 0) then
			rMean = NaN
			return
		end if

		! Compute the arithmetic mean, if missing; or, get its value
		n = count(.valid.rvX)
		if(present(rMeanIn)) then
			rMean = rMeanIn
		else
			if(n > 0) then
				rMean = sum(rvX, mask = .valid.rvX) / n
			else
				rMean = NaN
			end if
		end if
		if(present(rStdDevIn)) then
			rStdDev = rStdDevIn
		else
			if(n > 0) then
				rStdDev = sqrt(sum((rvX - rMean)**2, mask = .valid.rvX) / n)
			else
				rStdDev = NaN
			end if
		end if

		! Compute the skewness
		if(n > 0) then
			m3        = sum((rvX - rMean)**3, mask = .valid.rvX) / n
			rSkewness = m3 / rStdDev**3
		else
			rSkewness = NaN
		end if

		! Compute diagnostic quantities, if present
		if(present(rValidFraction)) then
			rValidFraction = float(n) / size(rvX)
		end if

	end function Skew


	! Compute the population kurtosis of a signal
	function Kurt(rvX, rMeanIn, rStdDevIn, rValidFraction) result(rKurtosis)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX				! Signal, whose kurtosis is needed
		real, intent(in), optional		:: rMeanIn			! Mean value, as computed by "Mean" function (optional, recomputed if missing)
		real, intent(in), optional		:: rStdDevIn		! Standard deviation, as computed by "StdDev" function (optional, recomputed if missing)
		real, intent(out), optional		:: rValidFraction	! Fraction of valid to total signal data (optional)
		real							:: rKurtosis

		! Locals
		integer	:: n
		real	:: rMean
		real	:: rStdDev
		real	:: m4

		! Check something is to be made
		if(size(rvX) <= 0) then
			rMean = NaN
			return
		end if

		! Compute the arithmetic mean, if missing; or, get its value
		n = count(.valid.rvX)
		if(present(rMeanIn)) then
			rMean = rMeanIn
		else
			if(n > 0) then
				rMean = sum(rvX, mask = .valid.rvX) / n
			else
				rMean = NaN
			end if
		end if
		if(present(rStdDevIn)) then
			rStdDev = rStdDevIn
		else
			if(n > 0) then
				rStdDev = sqrt(sum((rvX - rMean)**2, mask = .valid.rvX) / n)
			else
				rStdDev = NaN
			end if
		end if

		! Compute the skewness
		if(n > 0) then
			m4        = sum((rvX - rMean)**4, mask = .valid.rvX) / n
			rKurtosis = m4 / rStdDev**4 - 3.
		else
			rKurtosis = NaN
		end if

		! Compute diagnostic quantities, if present
		if(present(rValidFraction)) then
			rValidFraction = float(n) / size(rvX)
		end if

	end function Kurt


    ! Compute the sampling covariance between two signal samples; these samples should
    ! be the same size, and "error-paired", that is, whenever rvX(i) == NaN,
    ! then rvY(i) == NaN, and vice-versa.
	function Cov(rvX, rvY) result(rCov)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX
		real, dimension(:), intent(in)	:: rvY
		real							:: rCov

		! Locals
        integer :: n
        integer :: i
		real(8)	:: rSumX
		real(8)	:: rSumY
		real(8)	:: rSumXY

        ! Check it makes sense to proceed
        if(size(rvX) /= size(rvY)) then
        	rCov = NaN
        	return
        end if
        n = 0
        do i = 1, size(rvX)
        	if((.valid.rvX(i)) .and. (.valid.rvY(i))) n = n + 1
        end do
        if(n <= 1) then
            rCov = NaN
            return
        end if

		! Accumulate sums
		rSumX  = 0.d0
		rSumY  = 0.d0
		rSumXY = 0.d0
        do i = 1, size(rvX)
        	if((.valid.rvX(i)) .and. (.valid.rvY(i))) then
        		rSumX  = rSumX + rvX(i)
        		rSumY  = rSumY + rvY(i)
        		rSumXY = rSumXY + rvX(i)*rvY(i)
        	end if
        end do

		! Convert counts to covariance
		rCov = rSumXY/(n-1) - (rSumX/n)*(rSumY/n)*(float(n)/(n-1))

	end function Cov


	function QuantileScalar(rvX, rQuantile, iType) result(rQvalue)

		! Routine argument
		real, dimension(:), intent(in)	:: rvX			! Data vector
		real, intent(in)				:: rQuantile	! Quantile fraction (in [0.,1.] interval, inclusive)
		integer, intent(in), optional	:: iType		! Quantile type (QUANT_POPULATION, QUANT_1, ..., QUANT_9; see constant declaration for meaning)
		real							:: rQvalue		! Quantile value

		! Locals
		real, dimension(:), allocatable	:: rvXsorted
		integer							:: iQuantileType
		real							:: h
		real							:: m
		integer							:: n
		real							:: p
		integer							:: j
		real							:: g
		real							:: gamma

		! Check something is to be made
		if(size(rvX) == 1) then
			rQvalue = rvX(1)
			return
		elseif(size(rvX) < 1) then
			rQvalue = NaN
			return
		end if
		if(all(.invalid.rvX)) then
			rQvalue = NaN
			return
		end if
		if(.invalid.rQuantile) then
			rQvalue = NaN
			return
		end if

		! Answer for trivial cases
		if(rQuantile <= 0.) then
			rQvalue = minval(rvX, mask=.valid.rvX)
			return
		elseif(rQuantile >= 1.) then
			rQvalue = maxval(rvX, mask=.valid.rvX)
			return
		end if

		! Contract data vector to valid data only, and sort it
		rvXsorted = GetValidOnly(rvX)
		if(size(rvXsorted) == 1) then
			rQvalue = rvXsorted(1)
			return
		elseif(size(rvXsorted) < 1) then
			rQvalue = NaN
			return
		end if
		call quicksort(rvXsorted)

		! Assign actual quantile type
		if(present(iType)) then
			iQuantileType = iType
			if(iQuantileType == QUANT_POPULATION .and. size(rvXsorted) < size(rvx)) iQuantileType = QUANT_8
		else
			iQuantileType = QUANT_8
		end if

		! Compute the quantile value
		n = size(rvXsorted)
		p = rQuantile

		select case(iQuantileType)
		case(QUANT_POPULATION)
			h = n * p
			if(floor(h) == ceiling(h)) then
				! h is integer
				j = floor(h)
				if(j < 1) then
					rQvalue = rvXsorted(1)
				elseif(j >= n) then
					rQvalue = rvXsorted(n)
				else
					rQvalue = 0.5*(rvXsorted(j) + rvXsorted(j + 1))
				end if
			else
				! h is not integer
				j = ceiling(h)
				if(j < 1) then
					rQvalue = rvXsorted(1)
				elseif(j >= n) then
					rQvalue = rvXsorted(n)
				else
					rQvalue = rvXsorted(j)
				end if
			end if
		case(QUANT_1)
			h = n * p
			j = ceiling(h)
			if(j < 1) then
				rQvalue = rvXsorted(1)
			elseif(j > n) then
				rQvalue = rvXsorted(n)
			else
				rQvalue = rvXsorted(ceiling(h))
			end if
		case(QUANT_2)
			m = 0.
			j = floor(n*p + m)
			if(j >= 1 .and. j < n) then
				g = n*p + m - j
				if(g>1.e-6) then
					gamma = 1.
				else
					gamma = 0.5
				end if
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_3)
			j = nint(n * p)
			if(j < 1) then
				rQvalue = rvXsorted(1)
			elseif(j > n) then
				rQvalue = rvXsorted(n)
			else
				rQvalue = rvXsorted(j)
			end if
		case(QUANT_3_SAS)
			m = -0.5
			j = floor(n*p + m)
			if(j >= 1 .and. j < n) then
				g = n*p + m - j
				if(g<1.e-6 .and. mod(j,2)==0) then
					gamma = 1.
				else
					gamma = 0.
				end if
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_4)
			m = 0.
			j = floor(n*p + m)
			if(j >= 1 .and. j < n) then
				g = n*p + m - j
				gamma = g
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_5)
			m = 1./2.
			j = floor(n*p + m)
			if(j >= 1 .and. j < n) then
				g = n*p + m - j
				gamma = g
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_6)
			m = 0.
			j = floor((n+1)*p + m)
			if(j >= 1 .and. j < n) then
				g = (n+1)*p + m - j
				gamma = g
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_7)
			m = 1.
			j = floor((n-1)*p + m)
			if(j >= 1 .and. j < n) then
				g = (n-1)*p + m - j
				gamma = g
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_8)
			m = 1./3.
			j = floor((n+1./3.)*p + m)
			if(j >= 1 .and. j < n) then
				g = (n+1./3.)*p + m - j
				gamma = g
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case(QUANT_9)
			m = 3./8.
			j = floor((n+1./4.)*p + m)
			if(j >= 1 .and. j < n) then
				g = (n+1./4.)*p + m - j
				gamma = g
				rQvalue = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
			elseif(j < 1) then
				rQvalue = rvXsorted(1)
			else
				rQvalue = rvXsorted(n)
			end if
		case default
			rQvalue = NaN
		end select

	end function QuantileScalar


	function QuantileVector(rvX, rvQuantile, iType) result(rvQvalue)

		! Routine argument
		real, dimension(:), intent(in)		:: rvX			! Data vector
		real, dimension(:), intent(in)		:: rvQuantile	! Quantile fraction (in [0.,1.] interval, inclusive)
		integer, intent(in), optional		:: iType		! Quantile type (QUANT_POPULATION, QUANT_1, ..., QUANT_9; see constant declaration for meaning)
		real, dimension(size(rvQuantile))	:: rvQvalue		! Quantile value

		! Locals
		real, dimension(:), allocatable	:: rvXsorted
		integer							:: iQuantileType
		real							:: h
		integer							:: iQuantile
		real							:: m
		integer							:: n
		real							:: p
		integer							:: j
		real							:: g
		real							:: gamma

		! Check something is to be made
		if(size(rvQuantile) <= 0) then
			return	! No defined return value can be assigned here - rvQvalue does not exist
		end if
		if(size(rvX) == 1) then
			rvQvalue = rvX(1)
			return
		elseif(size(rvX) < 1) then
			rvQvalue = NaN
			return
		end if
		if(all(.invalid.rvX)) then
			rvQvalue = NaN
			return
		end if

		! Contract data vector to valid data only, and sort it
		rvXsorted = GetValidOnly(rvX)
		if(size(rvXsorted) == 1) then
			rvQvalue = rvXsorted(1)
			return
		elseif(size(rvXsorted) < 1) then
			rvQvalue = NaN
			return
		end if
		call quicksort(rvXsorted)

		! Assign actual quantile type
		if(present(iType)) then
			iQuantileType = iType
			if(iQuantileType == QUANT_POPULATION .and. size(rvXsorted) < size(rvX)) iQuantileType = QUANT_8
		else
			iQuantileType = QUANT_8
		end if

		! Main loop: iterate over quantiles
		do iQuantile = 1, size(rvQuantile)

			! Check something is to be made
			if(.invalid.rvQuantile(iQuantile)) then
				rvQvalue(iQuantile) = NaN
				cycle
			end if

			! Answer for trivial cases
			if(rvQuantile(iQuantile) <= 0.) then
				rvQvalue(iQuantile) = minval(rvX, mask=.valid.rvX)
				cycle
			elseif(rvQuantile(iQuantile) >= 1.) then
				rvQvalue(iQuantile) = maxval(rvX, mask=.valid.rvX)
				cycle
			end if

			! Compute the quantile value
			n = size(rvXsorted)
			p = rvQuantile(iQuantile)

			! Compute the value of h
			select case(iQuantileType)
			case(QUANT_POPULATION)
				h = n * p
				if(floor(h) == ceiling(h)) then
					! h is integer
					j = floor(h)
					if(j < 1) then
						rvQvalue(iQuantile) = rvXsorted(1)
					elseif(j >= n) then
						rvQvalue(iQuantile) = rvXsorted(n)
					else
						rvQvalue(iQuantile) = 0.5*(rvXsorted(j) + rvXsorted(j + 1))
					end if
				else
					! h is not integer
					j = ceiling(h)
					if(j < 1) then
						rvQvalue(iQuantile) = rvXsorted(1)
					elseif(j >= n) then
						rvQvalue(iQuantile) = rvXsorted(n)
					else
						rvQvalue(iQuantile) = rvXsorted(j)
					end if
				end if
			case(QUANT_1)
				h = n * p
				j = ceiling(h)
				if(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				elseif(j > n) then
					rvQvalue(iQuantile) = rvXsorted(n)
				else
					rvQvalue(iQuantile) = rvXsorted(j)
				end if
			case(QUANT_2)
				m = 0.
				j = floor(n*p + m)
				if(j >= 1 .and. j < n) then
					g = n*p + m - j
					if(g>1.e-6) then
						gamma = 1.
					else
						gamma = 0.5
					end if
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case(QUANT_3)
				j = nint(n * p)
				if(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				elseif(j > n) then
					rvQvalue(iQuantile) = rvXsorted(n)
				else
					rvQvalue(iQuantile) = rvXsorted(j)
				end if
			case(QUANT_3_SAS)
				m = -0.5
				j = floor(n*p + m)
				if(j >= 1 .and. j < n) then
					g = n*p + m - j
					if(g<1.e-6 .and. mod(j,2)==0) then
						gamma = 1.
					else
						gamma = 0.
					end if
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case(QUANT_4)
				m = 0.
				j = floor(n*p + m)
				if(j >= 1 .and. j < n) then
					g = n*p + m - j
					gamma = g
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
				if(rvQuantile(iQuantile) < 1./size(rvXsorted)) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					h = size(rvXsorted) * rvQuantile(iQuantile)
					rvQvalue(iQuantile) = rvXsorted(floor(h)) + (h - floor(h))*(rvXsorted(floor(h)+1) - rvXsorted(floor(h)))
				end if
			case(QUANT_5)
				m = 1./2.
				j = floor(n*p + m)
				if(j >= 1 .and. j < n) then
					g = n*p + m - j
					gamma = g
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case(QUANT_6)
				m = 0.
				j = floor((n+1)*p + m)
				if(j >= 1 .and. j < n) then
					g = (n+1)*p + m - j
					gamma = g
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case(QUANT_7)
				m = 1.
				j = floor((n-1)*p + m)
				if(j >= 1 .and. j < n) then
					g = (n-1)*p + m - j
					gamma = g
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case(QUANT_8)
				m = 1./3.
				j = floor((n+1./3.)*p + m)
				if(j >= 1 .and. j < n) then
					g = (n+1./3.)*p + m - j
					gamma = g
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case(QUANT_9)
				m = 3./8.
				j = floor((n+1./4.)*p + m)
				if(j >= 1 .and. j < n) then
					g = (n+1./4.)*p + m - j
					gamma = g
					rvQvalue(iQuantile) = (1.-gamma)*rvXsorted(j) + gamma*rvXsorted(j+1)
				elseif(j < 1) then
					rvQvalue(iQuantile) = rvXsorted(1)
				else
					rvQvalue(iQuantile) = rvXsorted(n)
				end if
			case default
				rvQvalue(iQuantile) = NaN
			end select

		end do

	end function QuantileVector


	! Compute the autocovariance of a signal up the specified number of lags,
	! by using the standard and the 2nd-stationary definitions, as given
	! respectively in R.B. Stull, "An Introduction to Boundary Layer Meteorology", Kluwer
	! Acedemic Publishers, 1988, and
	! W.N. Venables, B.D. Ripley, "Modern Applied Statistics with S", Springer, 2002.
	!
	function AutoCov(rvX, rvACov, iType) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)		:: rvX			! Signal (may contain NaN values)
		real, dimension(0:), intent(out)	:: rvACov		! Vector containing the desired values
		integer, intent(in), optional		:: iType		! Type of ACV (ACV_GENERAL, default: no stationarity assumption, ACV_2ND_ORDER:2nd order stationarity assumed (as in W. N. Venables,
		integer								:: iRetCode		! Flag indicating success (value = 0) or failure.

		! Locals
		integer	:: iLag
		integer	:: i
		integer	:: n
		real(8)	:: rSumA
		real(8)	:: rSumB
		real(8)	:: rSumAB
		real(8)	:: rMean
		integer	:: iNum
		logical	:: lGeneral

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(size(rvX) <= 0 .OR. size(rvACov) <= 0 .OR. size(rvACov) > size(rvX)) then
			rvACov = NaN
			iRetCode = 1
			return
		end IF
		n = size(rvX)

		! Determine type of processing
		if(present(iType)) then
			lGeneral = (iType == ACV_GENERAL)
		else
			lGeneral = .TRUE.
		end if

		! Compute autocovariance for each lag
		if(lGeneral) then

			! Compute means and averages on each lag set independently,
			! making no assumption on the stationarity of data set
			do iLag = 0, size(rvACov)-1

				! Compute means
				rSumA  = 0.d0
				rSumB  = 0.d0
				iNum = 0
				do i = 1, n - iLag
					if((.valid.rvX(i)) .and. (.valid.rvX(i+iLag))) then
						iNum   = iNum + 1
						rSumA  = rSumA + rvX(i)
						rSumB  = rSumB + rvX(i+iLag)
					end if
				end do

				! Compute autocovariance
				if(iNum > 0) then
					rSumAB = 0.d0
					do i = 1, n - iLag
						if((.valid.rvX(i)) .and. (.valid.rvX(i+iLag))) then
							rSumAB = rSumAB + (rvX(i) - rSumA/iNum) * (rvX(i+iLag) - rSumB/iNum)
						end if
					end do
					rvACov(iLag) = rSumAB/iNum
				else
					rvACov(iLag) = NaN
				end if

			end do

		else

			! Compute overall mean, assuming 2nd-order stationarity
			iNum  = 0
			rMean = 0.d0
			do i = 1, n
				if(.valid.rvX(i)) then
					iNum = iNum + 1
					rMean = rMean + rvX(i)
				end if
			end do
			rMean = rMean / iNum

			! Compute autocovariances with respect to the same overall mean
			do iLag = 0, size(rvACov)-1
				rSumAB = 0.d0
				do i = 1, n - iLag
					if((.valid.rvX(i)) .and. (.valid.rvX(i+iLag))) then
						rSumAB = rSumAB + (rvX(i) - rMean) * (rvX(i+iLag) - rMean)
					end if
				end do
				if(iNum > 0) then
					rvACov(iLag) = rSumAB/iNum
				else
					rvACov(iLag) = NaN
				end if
			end do

		end if

	end function AutoCov


	! Compute the autocorrellation of a signal up the specified number of lags,
	! by using the standard and the 2nd-stationary definitions, as given
	! respectively in R.B. Stull, "An Introduction to Boundary Layer Meteorology", Kluwer
	! Acedemic Publishers, 1988, and
	! W.N. Venables, B.D. Ripley, "Modern Applied Statistics with S", Springer, 2002.
	!
	function AutoCorr(rvX, rvACorr, iType) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)		:: rvX			! Signal (may contain NaN values)
		real, dimension(0:), intent(out)	:: rvACorr		! Vector containing the desired values
		integer, intent(in), optional		:: iType		! Type of ACV (ACV_GENERAL, default: no stationarity assumption, ACV_2ND_ORDER:2nd order stationarity assumed (as in W. N. Venables,
		integer								:: iRetCode		! Flag indicating success (value = 0) or failure.

		! Locals
		real, dimension(:), allocatable	:: rvACov

		! Compute the autocovariance
		allocate(rvACov(0:(size(rvACorr)-1)))
		iRetCode = AutoCov(rvX, rvACov, iType)
		if(iRetCode /= 0) then
			deallocate(rvACov)
			return
		end if

		! Scale autocovariance to autocorrelation
		if(abs(rvACov(0)) > 1.e-6) then
			rvACorr(1:) = rvACov(1:) / rvACov(0)
			rvACorr(0)  = 1.
		else
			rvACorr = NaN
		end if

	end function AutoCorr


	! Compute the autocovariance of a signal up the specified number of lags,
	! by using the direct summation method under the mandatory assumption of
	! second-order statoinarity.
	!
	! Warning: The formula used provides the same result as in R, and is
	! described in [Venables, 2002]. The actual equation, in section 14.1
	! of [Venables, 2002] is however incorrect: the lower summation limit
	! is stated to be MAX(1,-iLag), which should be MAX(1,1-iLag) instead.
	! The R implementation is correct however: the bug is in the manual only.
	!
	function CrossCov(rvX, rvY, rvCCov, iType) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX			! First signal (should contain no NaN values)
		real, dimension(:), intent(in)	:: rvY			! Second signal (should contain no NaN values)
		real, dimension(:), intent(out)	:: rvCCov		! Vector containing the desired values, dimensioned (-iLagMax:iLagMax) where iLagMax > 0
		integer, intent(in), optional	:: iType		! Type of ACV (ACV_GENERAL, default: no stationarity assumption, ACV_2ND_ORDER:2nd order stationarity assumed (as in W. N. Venables,
		integer							:: iRetCode		! Flag indicating success (value = 0) or failure.

		! Locals
		logical	:: lGeneral
		integer	:: iLag
		integer	:: iLagMax
		integer	:: i
		integer	:: iMin
		integer	:: iMax
		integer	:: n
		real(8)	:: rMeanX
		real(8)	:: rMeanY
		real(8)	:: rSumAB

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(size(rvX) <= 0 .OR. size(rvY) <= 0) then
			rvCCov = NaN
			iRetCode = 1
			return
		end IF
		if(size(rvX) /= size(rvY)) then
			rvCCov = NaN
			iRetCode = 2
			return
		end IF
		if(size(rvCCov) <= 0 .OR. size(rvCCov) > size(rvX)) then
			rvCCov = NaN
			iRetCode = 3
			return
		end IF
		if(mod(size(rvCCov),2) /= 1) then
			rvCCov = NaN
			iRetCode = 4
			return
		end IF
		if(any(.invalid.rvX) .OR. any(.invalid.rvY)) then
			rvCCov = NaN
			iRetCode = 5
			return
		end IF
		n       = size(rvX)
		iLagMax = (size(rvCCov) - 1) / 2

		! Determine type of processing
		if(present(iType)) then
			lGeneral = (iType == ACV_GENERAL)
		else
			lGeneral = .TRUE.
		end if

		! Compute autocovariance for each lag
		if(lGeneral) then

			! Compute autocovariances with respect to the same overall mean
			do iLag = -iLagMax, iLagMax
				iMin = max(1,1-iLag)
				iMax = min(n - iLag,n)
				rMeanX = sum(rvX(iMin:iMax)) / (iMax-iMin)
				rMeanY = sum(rvY(iMin:iMax)) / (iMax-iMin)
				rSumAB = 0.d0
				do i = iMin, iMax
					rSumAB = rSumAB + (rvX(i+iLag) - rMeanX) * (rvY(i) - rMeanY)
				end do
				rvCCov(iLag+iLagMax+1) = rSumAB / (iMax-iMin)
			end do

		else

			! Compute overall mean, assuming 2nd-order stationarity
			rMeanX = sum(rvX) / n
			rMeanY = sum(rvY) / n

			! Compute autocovariances with respect to the same overall mean
			do iLag = -iLagMax, iLagMax
				rSumAB = 0.d0
				do i = max(1,1-iLag), min(n - iLag,n)
					rSumAB = rSumAB + (rvX(i+iLag) - rMeanX) * (rvY(i) - rMeanY)
				end do
				rvCCov(iLag+iLagMax+1) = rSumAB / n
			end do

		end if

	end function CrossCov


	! Compute the autocorrelation of a signal up the specified number of lags,
	! by using the direct summation method.
	function CrossCorr(rvX, rvY, rvCCorr, iType) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvX			! First signal (may contain NaN values)
		real, dimension(:), intent(in)	:: rvY			! Second signal (may contain NaN values)
		real, dimension(:), intent(out)	:: rvCCorr		! Vector containing the desired values, dimensioned (-iLagMax:iLagMax) where iLagMax > 0
		integer, intent(in), optional	:: iType		! Type of ACV (ACV_GENERAL, default: no stationarity assumption, ACV_2ND_ORDER:2nd order stationarity assumed (as in W. N. Venables,
		integer							:: iRetCode		! Flag indicating success (value = 0) or failure.

		! Locals
		logical	:: lGeneral
		integer	:: iLag
		integer	:: iLagMax
		integer	:: i
		integer	:: iMin
		integer	:: iMax
		integer	:: n
		real(8)	:: rMeanX
		real(8)	:: rMeanY
		real(8)	:: rSigmaX
		real(8)	:: rSigmaY
		real(8)	:: rSumAB

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(size(rvX) <= 0 .OR. size(rvY) <= 0) then
			rvCCorr = NaN
			iRetCode = 1
			return
		end IF
		if(size(rvX) /= size(rvY)) then
			rvCCorr = NaN
			iRetCode = 2
			return
		end IF
		if(size(rvCCorr) <= 0 .OR. size(rvCCorr) > size(rvX)) then
			rvCCorr = NaN
			iRetCode = 3
			return
		end IF
		if(mod(size(rvCCorr),2) /= 1) then
			rvCCorr = NaN
			iRetCode = 4
			return
		end IF
		if(any(.invalid.rvX) .OR. any(.invalid.rvY)) then
			rvCCorr = NaN
			iRetCode = 5
			return
		end IF
		n       = size(rvX)
		iLagMax = (size(rvCCorr) - 1) / 2

		! Determine type of processing
		if(present(iType)) then
			lGeneral = (iType == ACV_GENERAL)
		else
			lGeneral = .TRUE.
		end if

		! Compute autocovariance for each lag
		if(lGeneral) then

			! Compute autocovariances with respect to the same overall mean
			do iLag = -iLagMax, iLagMax
				iMin = max(1,1-iLag)
				iMax = min(n - iLag,n)
				rMeanX  = sum(rvX(iMin:iMax)) / (iMax-iMin)
				rMeanY  = sum(rvY(iMin:iMax)) / (iMax-iMin)
				rSigmaX = sqrt(sum((rvX(iMin:iMax) - rMeanX)**2) / (iMax-iMin))
				rSigmaY = sqrt(sum((rvY(iMin:iMax) - rMeanY)**2) / (iMax-iMin))
				rSumAB = 0.d0
				do i = iMin, iMax
					rSumAB = rSumAB + (rvX(i+iLag) - rMeanX) * (rvY(i) - rMeanY)
				end do
				rvCCorr(iLag+iLagMax+1) = (rSumAB / (iMax-iMin)) / (rSigmaX*rSigmaY)
			end do

		else

			! Compute overall mean and std.dev., assuming 2nd-order stationarity
			rMeanX  = sum(rvX) / n
			rMeanY  = sum(rvY) / n
			rSigmaX = sqrt(sum((rvX - rMeanX)**2) / n)
			rSigmaY = sqrt(sum((rvY - rMeanY)**2) / n)

			! Compute autocovariances with respect to the same overall mean
			do iLag = -iLagMax, iLagMax
				rSumAB = 0.d0
				do i = max(1,1-iLag), min(n - iLag,n)
					rSumAB = rSumAB + (rvX(i+iLag) - rMeanX) * (rvY(i) - rMeanY)
				end do
				rvCCorr(iLag+iLagMax+1) = (rSumAB / n) / (rSigmaX*rSigmaY)
			end do

		end if

	end function CrossCorr


	! Partial autocorrelation values, from autocorrelation. Useful, to determine
	! the order of an autoregressive process.
	function PartialAutoCorr(rvACov) result(rvPACorr)

		! Routine arguments
		real, dimension(0:), intent(in)	:: rvACov		! Autocovariance values
		real, dimension(size(rvACov)-1)	:: rvPACorr		! Partial autocorrelation, same indexing convention as above

		! Locals
		real, dimension(:), allocatable			:: phi
		real, dimension(:), allocatable			:: phiNew
		real, dimension(:), allocatable			:: rho
		real									:: numer
		real									:: denom
		real									:: total
		integer									:: j
		integer									:: k
		integer									:: km1
		integer									:: n

		! Check no gaps exist in autocorrelation, and they constitute a non-negative
		! decreasing sequence (the PACF makes sense in case of autoregressive
		! processes)
		if(any(.invalid.rvACov)) then
			rvPACorr = NaN
			return
		end if
		n = size(rvACov) - 1
		if(rvACov(0) <= 0.) then
			rvPACorr = NaN
			return
		end if

		! Reserve workspace
		allocate(phi(n), phiNew(n), rho(n))
		phi = 0.d0
		rho = 0.d0

		! Compute partial autocorrelation by Durbin-Levinson algorithm
		! (see [Brockwell, 2002], section 2.5.1, for clarifications).
		! The implementation follows prof. G.R. Ihaka's (see [Ihaka, web1])
		rho = rvACov(1:n)/rvACov(0)
		phi(1) = rho(1)
		rvPACorr(1) = phi(1)

		do k = 2, n
			km1 = k - 1
			total = 0.d0
			do j = 1, km1
				total = total + phi(j)*rho(km1-j+1)
			end do
			numer = rho(k) - total
			denom = 1.d0 - dot_product(phi(1:km1),rho(1:km1))
			phi(k) = numer / denom
			do j = 1, km1
				phiNew(j) = phi(j) - phi(k) * phi(km1-j+1)
			end do
			phi(1:km1) = phiNew(1:km1)
			rvPACorr(k) = phi(k)
		end do

		! Leave
		deallocate(phi, phiNew, rho)

	end function PartialAutoCorr


	! Estimate the Euleriam decorrelation time of a signal
	!
	function EulerianTime(rDataRate, rvX, rMaxEulerianTime, rEulerianTime, rvACorr) result(iRetCode)

		! Routine arguments
		real, intent(in)				:: rDataRate			! Data acquisition rate (Hz)
		real, dimension(:), intent(in)	:: rvX					! Signal (any unit)
		real, intent(in)				:: rMaxEulerianTime		! Maximum Eulerian time to consider
		real, intent(out)				:: rEulerianTime		! Estimate of Eulerian decorrelation time (s)
		real, dimension(:), allocatable, optional	:: rvACorr	! Autocorrelation found, for diagnostic purposes
		integer							:: iRetCode

		! Locals
		real, dimension(:), allocatable	:: rvC
		integer							:: iErrCode
		integer							:: iMaxLag
		integer							:: i

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(rDataRate <= 0. .or. rMaxEulerianTime <= 0. .or. size(rvX) <= 0) then
			rEulerianTime = NaN
			iRetCode = 1
			return
		end if
		if(any(.invalid.rvX)) then
			rEulerianTime = NaN
			iRetCode = 2
			return
		end if

		! Compute the maximum lag
		iMaxLag = rMaxEulerianTime * rDataRate
		if(iMaxLag >= size(rvX)) then
			rEulerianTime = NaN
			iRetCode = 3
			return
		end if
		if(iMaxLag <= 0) then
			rEulerianTime = 0.
			iRetCode = 4
			return
		end if

		! Compute autocorrelations
		allocate(rvC(0:iMaxLag))
		iErrCode = AutoCorr(rvX, rvC, ACV_2ND_ORDER)
		if(iErrCode /= 0) then
			rEulerianTime = NaN
			iRetCode = 5
			deallocate(rvC)
			return
		end if

		! Estimate the Eulerian decorrelation time
		rEulerianTime = iMaxLag / rDataRate
		do i = 1, iMaxLag - 1
			if(rvC(i) < 1.96/sqrt(float(size(rvX) - i))) then
				rEulerianTime = (i-1) / rDataRate
				if(present(rvACorr)) then
					if(allocated(rvACorr)) deallocate(rvACorr)
					allocate(rvACorr(0:iMaxLag))
					rvACorr = rvC
				end if
				deallocate(rvC)
				return
			end if
		end do
		deallocate(rvC)
		iRetCode = 6

	end function EulerianTime


	! Remove linear trend, if any, from a signal.
	!
	! The signal is modified by eliminating the trend found, but
	! leaving the riginal mean unchanged.
	function RemoveLinearTrend(rvX, rvY, rMultiplier, rOffset) result(iRetCode)

		! Routine argument
		real(8), dimension(:), intent(in)	:: rvX			! Index signal (typically time, in floating point form)
		real, dimension(:), intent(inout)	:: rvY			! Signal to remove the trend from
		real(8), intent(out)				:: rMultiplier	! Multiplier of trend line
		real(8), intent(out)				:: rOffset		! Offset of trend line
		integer								:: iRetCode

		! Locals
		integer	:: n
		real(8)	:: rSx
		real(8)	:: rSy
		real(8)	:: rSxx
		real(8)	:: rSxy
		real(8)	:: rDelta
		real(8)	:: rMeanBeforeDetrend
		real(8)	:: rMeanAfterDetrend

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check input parameters
		if(size(rvX) <= 0 .or. size(rvY) <= 0) then
			iRetCode = 1
			return
		end if
		if(size(rvX) /= size(rvY)) then
			iRetCode = 2
			return
		end if
		if(any(.invalid.rvX) .or. any(.invalid.rvY)) then
			iRetCode = 3
			return
		end if

		! Compute counts and sums
		n    = size(rvX)
		rSx  = sum(rvX)
		rSy  = sum(dble(rvY))
		rSxx = dot_product(rvX,rvX)
		rSxy = dot_product(rvX,dble(rvY))
		rMeanBeforeDetrend = rSy / n

		! Compute multiplier and offset
		rDelta      = n*rSxx - rSx**2
		if(rDelta <= 0.d0) then
			iRetCode = 4
			return
		end if
		rOffset     = (rSxx*rSy - rSx*rSxy)/rDelta
		rMultiplier = (n*rSxy - rSx*rSy)/rDelta

		! Subtract the linear trend
		rvY = rvY - rMultiplier*(rvX - rSx/n)

		! Remove residual average, and add back the original mean
		rMeanAfterDetrend = sum(dble(rvY)) / n
		rvY = rvY - rMeanAfterDetrend + rMeanBeforeDetrend
		rOffset = rOffset - rMeanAfterDetrend + rMeanBeforeDetrend

	end function RemoveLinearTrend

	! ********************************
	! * Members of Time<series class *
	! ********************************

	function tsCreateEmpty(this, n) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this			! Current time series
		integer, intent(in)					:: n			! Number of elements (must be positive)
		integer								:: iRetCode		! Return code (0 if successful completion; any non-zero in case of error(s))

		! Locals
		integer	:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check input parameters
		if(n <= 0) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue)) deallocate(this % rvValue)
		allocate(this % rvTimeStamp(n), stat = iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		allocate(this % rvValue(n), stat = iErrCode)
		if(iErrCode /= 0) then
			deallocate(this % rvTimeStamp)
			iRetCode = 2
			return
		end if

		! Fill with appropriate initial values
		this % rvTimeStamp = NaN_8
		this % rvValue     = NaN

	end function tsCreateEmpty


	! Copy constructor, creates a duplicate of current time series
	function tsCreateFromTimeSeries(this, ts, lForceWellSpacedMonotonic) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(out)		:: this
		type(TimeSeries), intent(in)		:: ts
		logical, intent(in), optional		:: lForceWellSpacedMonotonic	! If .false. (default) just copy the series as it is. If .true., rearrange the original series so that time stamps form a type-0 well spaced sequence
		integer								:: iRetCode

		! Locals
		integer	:: i
		integer	:: n
		integer	:: m
		integer	:: idx
		integer	:: iErrCode
		real(8)	:: rDeltaTime
		real(8)	:: rMinTimeStamp
		real(8)	:: rMaxTimeStamp
		integer	:: iWellSpaced
		real(8), dimension(:), allocatable	:: rvTimeStamp
		real(4), dimension(:), allocatable	:: rvValues
		logical								:: lTimeExpand

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Decide which type of processing to do
		if(present(lForceWellSpacedMonotonic)) then
			lTimeExpand = lForceWellSpacedMonotonic
		else
			lTimeExpand = .false.
		end if

		! Check there is something to copy (leave current series unchanged if not)
		n = ts % size()
		if(n <= 0) then
			iRetCode = 1
			return
		end if

		! Dispatch processing according to type
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue)) deallocate(this % rvValue)
		if(lTimeExpand) then

			! Check conditions on time stamp (in particular, well-spacedness) to be
			! true enough for the expansion-while-copy to occur
			iWellSpaced = ts % timeIsWellSpaced(rDeltaTime)
			select case(iWellSpaced)

			case(0)	! Well-spaced, no gaps: just copy (reordering made)

				! Reserve workspace in copy, based on original
				allocate(this % rvTimeStamp(n), stat = iErrCode)
				if(iErrCode /= 0) then
					iRetCode = 2
					return
				end if
				allocate(this % rvValue(n), stat = iErrCode)
				if(iErrCode /= 0) then
					deallocate(this % rvTimeStamp)
					iRetCode = 2
					return
				end if

				! Fill with appropriate initial values
				iRetCode           = ts % getTimeStamp(rvTimeStamp)
				this % rvTimeStamp = rvTimeStamp
				iRetCode           = ts % getValues(rvValues)
				this % rvValue     = rvValues

				! Reorder with respect to time, to make sure of quasi-monotonicity (which becomes monotonicity, if
				! well-spacing with a positive delta time is guaranteed
				call this % timeReorder()

			case(1)	! Well-spaced, but with at least one gap: time-expand (incidentally, result is monotonic)

				! Make resulting series time-regular
				iRetCode = ts % getTimeStamp(rvTimeStamp)
				if(iRetCode /= 0) then
					iRetCode = 3
					return
				end if
				iRetCode = ts % getValues(rvValues)
				if(iRetCode /= 0) then
					iRetCode = 3
					return
				end if
				rMinTimeStamp = minval(rvTimeStamp, mask=.valid.rvTimeStamp)
				rMaxTimeStamp = maxval(rvTimeStamp, mask=.valid.rvTimeStamp)
				if((.invalid.rMinTimeStamp) .or. (.invalid.rMaxTimeStamp)) then
					iRetCode = 4
					return
				end if

				! Count time-expanded size, and reserve workspace based on it
				m = nint((rMaxTimeStamp - rMinTimeStamp) / rDeltaTime) + 1
				if(m <= 0) then
					iRetCode = 5
					return
				end if
				allocate(this % rvTimeStamp(m), stat = iErrCode)
				if(iErrCode /= 0) then
					iRetCode = 2
					return
				end if
				allocate(this % rvValue(m), stat = iErrCode)
				if(iErrCode /= 0) then
					deallocate(this % rvTimeStamp)
					iRetCode = 2
					return
				end if

				! Initialize value vector to invalid, so that any non-filled value will make self-evident as a gap
				this % rvValue = NaN

				! Transfer data by their time index
				do i = 1, n
					idx = nint((rvTimeStamp(i) - rMinTimeStamp) / rDeltaTime) + 1
					if(idx < 1 .or. idx > m) cycle
					this % rvValue(idx) = rvValues(i)
				end do

				! Build time stamp vector
				this % rvTimeStamp = [(rMinTimeStamp + rDeltaTime*(i-1), i = 1, m)]

			case default	! -1 and 2 cases: no time regularity, abandon match

				iRetCode = 4
				return

			end select

		else

			! Just-copy-it path

			! Reserve workspace in copy, based on original
			allocate(this % rvTimeStamp(n), stat = iErrCode)
			if(iErrCode /= 0) then
				iRetCode = 2
				return
			end if
			allocate(this % rvValue(n), stat = iErrCode)
			if(iErrCode /= 0) then
				deallocate(this % rvTimeStamp)
				iRetCode = 2
				return
			end if

			! Fill with appropriate initial values
			iRetCode           = ts % getTimeStamp(rvTimeStamp)
			this % rvTimeStamp = rvTimeStamp
			iRetCode           = ts % getValues(rvValues)
			this % rvValue     = rvValues

		end if

	end function tsCreateFromTimeSeries


	function tsIsEmpty(this) result(lIsEmpty)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this			! Current time series
		logical							:: lIsEmpty		! Flag indicating (.true.) whether a time series is still unallocated or empty, or (.true.) not

		! Locals
		! --none--

		! Check allocation state
		if(.not.allocated(this % rvTimeStamp) .or. .not.allocated(this % rvValue)) then
			! Not yet allocated
			lIsEmpty = .true.
		else
			if(size(this % rvTimeStamp) <= 0 .or. size(this % rvValue) <= 0) then
				lIsEmpty = .true.
			else
				! Both vectors are allocated: do they contain something?
				lIsEmpty = all(.invalid.this % rvTimeStamp) .or. all(.invalid.this % rvValue)
			end if
		end if

	end function tsIsEmpty


	function tsCreateFromDataVector(this, rvValues, rTimeFrom, rDeltaTime) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this			! Current time series
		real, dimension(:), intent(in)		:: rvValues		! Data values
		real(8), intent(in)					:: rTimeFrom	! Initial date-time (s since the Epoch)
		real(8), intent(in), optional		:: rDeltaTime	! Time difference between two any series elements (default: 1.d0; must be positive if present)
		integer								:: iRetCode		! Return code (0 if successful completion; any non-zero in case of error(s))

		! Locals
		integer	:: iErrCode
		integer	:: i
		integer	:: n
		real(8)	:: rTimeIncrement

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check input parameters
		n = size(rvValues)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		if(present(rDeltaTime)) then
			if(rDeltaTime <= 0.d0) then
				iRetCode = 2
				return
			else
				rTimeIncrement = rDeltaTime
			end if
		else
			rTimeIncrement = 1.d0
		end if

		! Reserve workspace
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue)) deallocate(this % rvValue)
		allocate(this % rvTimeStamp(n), stat = iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		allocate(this % rvValue(n), stat = iErrCode)
		if(iErrCode /= 0) then
			deallocate(this % rvTimeStamp)
			iRetCode = 3
			return
		end if

		! Fill with appropriate initial values
		this % rvTimeStamp = [(rTimeFrom + rTimeIncrement*(i-1), i = 1, n)]
		this % rvValue     = rvValues

	end function tsCreateFromDataVector


	function tsCreateFromTimeAndDataVectors(this, rvTimeStamp, rvValues) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this			! Current time series
		real(8), dimension(:), intent(in)	:: rvTimeStamp	! Time stamp values
		real, dimension(:), intent(in)		:: rvValues		! Data values (rvValue(i) corresponds to rvTimeStamp(i), i=1,...)
		integer								:: iRetCode		! Return code (0 if successful completion; any non-zero in case of error(s))

		! Locals
		integer	:: iErrCode
		integer	:: i
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check input parameters
		n = size(rvValues)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		if(n /= size(rvTimeStamp)) then
			iRetCode = 2
			return
		end if

		! Reserve workspace
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue)) deallocate(this % rvValue)
		allocate(this % rvTimeStamp(n), stat = iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		allocate(this % rvValue(n), stat = iErrCode)
		if(iErrCode /= 0) then
			deallocate(this % rvTimeStamp)
			iRetCode = 3
			return
		end if

		! Fill with appropriate initial values
		do i = 1, n
			this % rvTimeStamp(i) = rvTimeStamp(i)
			this % rvValue(i)     = rvValues(i)
		end do

	end function tsCreateFromTimeAndDataVectors


	! Shift time stamp values by a given time difference (useful for example when changing a posticipated
	! time stamp to an anticipated one
	subroutine tsTimeShift(this, deltaTime)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this
		real(8), intent(in)					:: deltaTime

		! Locals
		! --none--

		! Apply shift operator in place
		this % rvTimeStamp = this % rvTimeStamp + deltaTime

	end subroutine tsTimeShift


	! Reorder time stamp increasing, sorting values in the meanwhile
	subroutine tsTimeReorder(this)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this

		! Locals
		integer								:: n, i
		integer, dimension(:), allocatable	:: ivIdx
		real, dimension(:), allocatable		:: rvValue2

		! Check something is to be made
		n = size(this % rvTimeStamp)
		if(n <= 1) return	! Do nothing for empty time stamp vector

		! Reindex time stamp vector while sorting it
		allocate(ivIdx(n), rvValue2(n))
		ivIdx = [(i, i=1, n)]
		call quicksort_idx_8(this % rvTimeStamp, ivIdx)
		do i = 1, n
			rvValue2(i) = this % rvValue(ivIdx(i))
		end do
		this % rvValue = rvValue2
		deallocate(ivIdx, rvValue2)

	end subroutine tsTimeReorder


	function tsGetSingleItem(this, iItemIdx, rTimeStamp, rValue) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		integer, intent(in)				:: iItemIdx
		real(8), intent(out)			:: rTimeStamp
		real, intent(out)				:: rValue
		integer							:: iRetCode

		! Locals
		! -none-

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(size(this % rvTimeStamp) <= 0) then
			rTimeStamp = NaN_8
			rValue     = NaN
			iRetCode   = 1
			return
		end if
		if(iItemIdx <= 0 .or. iItemIdx > size(this % rvTimeStamp)) then
			rTimeStamp = NaN_8
			rValue     = NaN
			iRetCode   = 2
			return
		end if

		! Gather value
		rTimeStamp = this % rvTimeStamp(iItemIdx)
		rValue     = this % rvValue(iItemIdx)

	end function tsGetSingleItem


	function tsGetTimeStamp(this, rvTimeStamp) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvTimeStamp
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be made
		n = size(this % rvTimeStamp)
		if(n <= 0) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
		allocate(rvTimeStamp(n))

		! Transfer values
		rvTimeStamp = this % rvTimeStamp

	end function tsGetTimeStamp


	function tsGetValues(this, rvValues) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)					:: this
		real(4), dimension(:), allocatable, intent(out)	:: rvValues
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be made
		n = size(this % rvValue)
		if(n <= 0) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rvValues)) deallocate(rvValues)
		allocate(rvValues(n))

		! Transfer values
		rvValues = this % rvValue

	end function tsGetValues


	function tsGetTimeSpan(this, rMinTimeStamp, rMaxTimeStamp) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		real(8), intent(out)			:: rMinTimeStamp
		real(8), intent(out)			:: rMaxTimeStamp
		integer							:: iRetCode

		! Locals
		! - --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(this % isEmpty()) then
			rMinTimeStamp = NaN_8
			rMaxTimeStamp = NaN_8
			iRetCode   = 1
			return
		end if

		! Compute time bounds, even if some invalid time stamps exist
		rMinTimeStamp = minval(this % rvTimeStamp, mask = .valid.this % rvTimeStamp)
		rMaxTimeStamp = maxval(this % rvTimeStamp, mask = .valid.this % rvTimeStamp)

	end function tsGetTimeSpan


	function tsGetTimeSubset(this, ts, timeFrom, timeTo) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(out)		:: this
		type(TimeSeries), intent(in)		:: ts
		real(8), intent(in)					:: timeFrom
		real(8), intent(in)					:: timeTo
		integer								:: iRetCode

		! Locals
		integer	:: n, m
		integer	:: i, j
		integer	:: iErrCode
		real(8)	:: rMinTime
		real(8)	:: rMaxTime
		real(8), dimension(:), allocatable	:: rvTimeStamp
		real(4), dimension(:), allocatable	:: rvValues

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace in copy, based on original
		n = ts % size()
		if(n <= 0) then
			iRetCode = 1
			return
		end if

		! Fill with appropriate initial values
		iRetCode           = ts % getTimeStamp(rvTimeStamp)
		this % rvTimeStamp = rvTimeStamp
		iRetCode           = ts % getValues(rvValues)
		this % rvValue     = rvValues

		! Count subset size, and if zero return doing nothing
		rMinTime = min(timeFrom, timeTo)	! Just a safeguard
		rMaxTime = max(timeFrom, timeTo)	! Just a safeguard
		m = count(rvTimeStamp >= rMinTime .and. rvTimeStamp <= rMaxTime)
		if(m <= 0) then
			iRetCode = 2
			return
		end if

		! Reserve workspace
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue)) deallocate(this % rvValue)
		allocate(this % rvTimeStamp(m), stat = iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		allocate(this % rvValue(m), stat = iErrCode)
		if(iErrCode /= 0) then
			deallocate(this % rvTimeStamp)
			iRetCode = 3
			return
		end if

		! Fill with data in time range, preserving their order
		j = 0
		do i = 1, n
			if(rvTimeStamp(i) >= rMinTime .and. rvTimeStamp(i) <= rMaxTime) then
				j = j + 1
				this % rvTimeStamp(j) = rvTimeStamp(i)
				this % rvValue(j)     = rvValues(i)
			end if
		end do

	end function tsGetTimeSubset


	function tsGetMonth(this, ts, iMonth) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(out)		:: this
		type(TimeSeries), intent(in)		:: ts
		integer, intent(in)					:: iMonth
		integer								:: iRetCode

		! Locals
		integer	:: n, m
		integer	:: i, j
		integer	:: iErrCode
		real(8), dimension(:), allocatable	:: rvTimeStamp
		real(4), dimension(:), allocatable	:: rvValues
		integer, dimension(:), allocatable	:: ivMonth

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reserve workspace in copy, based on original
		n = ts % size()
		if(n <= 0) then
			iRetCode = 1
			return
		end if

		! Check parameters
		if(iMonth < 1 .or. iMonth > 12) then
			iRetCode = 2
			return
		end if

		! Fill with appropriate initial values
		iRetCode           = ts % getTimeStamp(rvTimeStamp)
		this % rvTimeStamp = rvTimeStamp
		iRetCode           = ts % getValues(rvValues)
		this % rvValue     = rvValues
		iErrCode = timeGetMonth(rvTimeStamp, ivMonth)

		! Count subset size, and if zero return doing nothing
		m = count(ivMonth == iMonth)
		if(m <= 0) then
			iRetCode = 3
			return
		end if

		! Reserve workspace
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue)) deallocate(this % rvValue)
		allocate(this % rvTimeStamp(m), stat = iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 4
			return
		end if
		allocate(this % rvValue(m), stat = iErrCode)
		if(iErrCode /= 0) then
			deallocate(this % rvTimeStamp)
			iRetCode = 5
			return
		end if

		! Fill with data in time range, preserving their order
		j = 0
		do i = 1, n
			if(ivMonth(i) == iMonth) then
				j = j + 1
				this % rvTimeStamp(j) = rvTimeStamp(i)
				this % rvValue(j)     = rvValues(i)
			end if
		end do

	end function tsGetMonth


	function tsPutSingleItem(this, iItemIdx, rTimeStamp, rValue) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this
		integer, intent(in)					:: iItemIdx
		real(8), intent(in)					:: rTimeStamp
		real, intent(in)					:: rValue
		integer								:: iRetCode

		! Locals
		! -none-

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(size(this % rvTimeStamp) <= 0) then
			iRetCode   = 1
			return
		end if
		if(iItemIdx <= 0 .or. iItemIdx > size(this % rvTimeStamp)) then
			iRetCode   = 2
			return
		end if

		! Gather value
		this % rvTimeStamp(iItemIdx) = rTimeStamp
		this % rvValue(iItemIdx)     = rValue

	end function tsPutSingleItem


	function tsSize(this) result(iNumValues)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		integer							:: iNumValues

		! Locals
		! --none--

		! Get the information desired
		if(this % isEmpty()) then
			iNumValues = 0
		else
			iNumValues = min(size(this % rvTimeStamp), size(this % rvValue))
		end if

	end function tsSize


	! Check the current time series has the same time stamps of another, in the very
	! same order. If the answer is .true., the two series are non-empty, their time stamps
	! are always valid, and may be thought as components of a larger multivariate series.
	function tsIsSameTimes(this, ts) result(lTimesAreSame)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		type(TimeSeries), intent(in)	:: ts
		logical							:: lTimesAreSame

		! Locals
		integer								:: iErrCode
		integer								:: i
		real(8), dimension(:), allocatable	:: rvTimeStamp

		! Get the information desired
		if(this % isEmpty() .or. ts % isEmpty()) then
			lTimesAreSame = .false.
			return
		end if
		iErrCode = ts % getTimeStamp(rvTimeStamp)
		if(iErrCode /= 0) then
			lTimesAreSame = .false.
			if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
			return
		end if
		if(any(.invalid.rvTimeStamp) .or. any(.invalid.this % rvTimeStamp)) then
			lTimesAreSame = .false.
			if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
			return
		end if
		lTimesAreSame = .true.
		do i = 1, size(rvTimeStamp)
			lTimesAreSame = lTimesAreSame .and. (abs(rvTimeStamp(i) - this % rvTimeStamp(i)) < 4.*epsilon(rvTimeStamp(i)))
		end do

	end function tsIsSameTimes


	subroutine tsSummary(this, iNumValues, rValidPercentage, rMin, rMean, rStdDev, rMax, rSkew, rKurt)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		integer, intent(out)			:: iNumValues
		real, intent(out)				:: rValidPercentage
		real, intent(out)				:: rMin
		real, intent(out)				:: rMean
		real, intent(out)				:: rStdDev
		real, intent(out)				:: rMax
		real, intent(out), optional		:: rSkew
		real, intent(out), optional		:: rKurt

		! Locals
		! -none-

		! Get size and valid count
		if(.not.allocated(this % rvValue)) then
			iNumValues       = 0.
			rValidPercentage = 0.
			rMin             = NaN
			rMean            = NaN
			rStdDev          = NaN
			rMax             = NaN
			if(present(rSkew)) rSkew = NaN
			if(present(rKurt)) rKurt = NaN
		else
			iNumValues = size(this % rvValue)
			if(iNumValues > 0) then
				rValidPercentage = 100.0 * count(.valid. this % rvValue) / iNumValues
				rMin             = minval(this % rvValue, mask = .valid. this % rvValue)
				rMean            = sum(this % rvValue, mask = .valid. this % rvValue) / iNumValues
				rStdDev          = sqrt(sum((this % rvValue - rMean)**2, mask = .valid. this % rvValue) / iNumValues)
				rMax             = maxval(this % rvValue, mask = .valid. this % rvValue)
				if(present(rSkew)) rSkew = Skew(this % rvValue, rMeanIn=rMean, rStdDevIn=rStdDev)
				if(present(rKurt)) rKurt = Kurt(this % rvValue, rMeanIn=rMean, rStdDevIn=rStdDev)
			else
				rValidPercentage = 0.
				rMin             = NaN
				rMean            = NaN
				rStdDev          = NaN
				rMax             = NaN
				if(present(rSkew)) rSkew = NaN
				if(present(rKurt)) rKurt = NaN
			end if
		end if

	end subroutine tsSummary


	subroutine tsRangeInvalidate(this, rMin, rMax)

		! Routine arguments
		class(TimeSeries), intent(inout)	:: this
		real, intent(in)					:: rMin
		real, intent(in)					:: rMax

		! Locals
		real	:: rMinVal, rMaxVal

		! Ensure limits ordering
		if(rMin <= rMax) then
			rMinVal = rMin
			rMaxVal = rMax
		else
			rMinVal = rMax
			rMaxVal = rMin
		end if

		! Invalidate by Range
		if(.not.this % isEmpty()) then
			call RangeInvalidate(this % rvValue, rMinVal, rMaxVal)
		end if

	end subroutine tsRangeInvalidate


	function tsTimeMonotonic(this) result(lIsMonotonic)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		logical							:: lIsMonotonic

		! Locals
		integer		:: n
		integer		:: i

		! Check parameters
		if(this % isEmpty()) then
			lIsMonotonic = .false.
			return
		end if
		n = size(this % rvTimeStamp)
		if(n <= 1) then
			lIsMonotonic = .false.
			return
		end if

		! Check time stamps are strictly increasing
		lIsMonotonic = .true.
		do i = 2, n
			if(this % rvTimeStamp(i-1) >= this % rvTimeStamp(i)) then
				lIsMonotonic = .false.
				return
			end if
		end do

	end function tsTimeMonotonic


	function tsTimeQuasiMonotonic(this) result(lIsMonotonic)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		logical							:: lIsMonotonic

		! Locals
		integer		:: n
		integer		:: i

		! Check parameters
		if(this % isEmpty()) then
			lIsMonotonic = .false.
			return
		end if
		n = size(this % rvTimeStamp)
		if(n <= 1) then
			lIsMonotonic = .false.
			return
		end if

		! Check time stamps are strictly increasing
		lIsMonotonic = .true.
		do i = 2, n
			if(this % rvTimeStamp(i-1) > this % rvTimeStamp(i)) then
				lIsMonotonic = .false.
				return
			end if
		end do

	end function tsTimeQuasiMonotonic


	function tsTimeGapless(this) result(lIsGapless)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		logical							:: lIsGapless

		! Locals
		integer		:: n
		integer		:: i

		! Check parameters
		if(this % isEmpty()) then
			lIsGapless = .false.
			return
		end if
		n = size(this % rvTimeStamp)
		if(n <= 1) then
			lIsGapless = .false.
			return
		end if

		! Check time stamps are strictly increasing
		lIsGapless = .true.
		do i = 1, n
			if(.invalid.this % rvTimeStamp(i)) then
				lIsGapless = .false.
				return
			end if
		end do

	end function tsTimeGapless


	! Note: Time well-spacing implies strict monotonicity by construction
	function tsTimeWellSpaced(this, rTimeStep, iNumGaps) result(iWellSpacingType)

		! Routine arguments
		class(TimeSeries), intent(in)	:: this
		real(8), intent(out), optional	:: rTimeStep			! NaN in case of non-well-spaced data
		integer, intent(out), optional	:: iNumGaps				! -1 in case of non-well-spaced data
		integer							:: iWellSpacingType		! -1:well-spacing cannot be determined; 0:well-spaced, no gaps;
																! 1:well-spaced, with at least one gap;
		! Locals												! 2:not well-spaced (irregular time step)
		integer		:: i
		integer		:: n
		real(8)		:: rDelta
		real(8)		:: rQuotient
		real(8)		:: rMinDelta
		integer		:: iQuotient
		integer		:: iMaxQuotient
		integer		:: iNumGapsFound

		! Check parameters
		if(this % isEmpty()) then
			iWellSpacingType = -1
			if(present(rTimeStep)) rTimeStep = NaN_8
			if(present(iNumGaps))  iNumGaps  = -1
			return
		end if
		n = size(this % rvTimeStamp)
		if(n <= 1) then
			! Degenerate case: less than two data available, success assumed
			iWellSpacingType = 0
			if(present(rTimeStep)) rTimeStep = 0.d0
			if(present(iNumGaps))  iNumGaps  = 0
			return
		end if

		! First pass: find the minimum positive difference between any two consecutive time stamps
		! (zero differences are allowed to occur, due to coarse-grained resolution of some
		! data acquisition timing systems; an example of data sets for which zero time differences
		! are allowed to occur is the SonicLib format
		rMinDelta = huge(rMinDelta)
		do i = 2, n
			rDelta = this % rvTimeStamp(i) - this % rvTimeStamp(i-1)
			if(rDelta > 0.d0) rMinDelta = min(rDelta, rMinDelta)
		end do

		! Second pass: check all the positive time differences are integer multiples of the minimum
		! delta
		iNumGapsFound = 0
		do i = 2, n
			rDelta = this % rvTimeStamp(i) - this % rvTimeStamp(i-1)
			rQuotient = rDelta / rMinDelta
			iQuotient = floor(rQuotient)
			if(rQuotient - iQuotient <= 10.0*epsilon(rQuotient)) then
				iMaxQuotient = max(iQuotient, iMaxQuotient)
				if(iQuotient > 1) iNumGapsFound = iNumGapsFound + 1
			else
				iWellSpacingType = 2	! Not well-spaced
				if(present(rTimeStep)) rTimeStep = NaN_8
				if(present(iNumGaps))  iNumGaps  = -1
				return
			end if
		end do

		! Decide the final result based on counters evaluated so far
		if(iNumGapsFound > 0) then
			iWellSpacingType = 1	! Well-spaced, with one gap
			if(present(rTimeStep)) rTimeStep = rMinDelta
			if(present(iNumGaps))  iNumGaps  = iNumGapsFound
		else
			iWellSpacingType = 0	! Well-spaced, no time gaps (ideal condition)
			if(present(rTimeStep)) rTimeStep = rMinDelta
			if(present(iNumGaps))  iNumGaps  = 0
		end if

	end function tsTimeWellSpaced


	! Aggregate data of a time series according to a positive time difference,
	! or a negative code indicating time divisions like month and year.
	! Result is a time series, containing the aggregated values and time
	! stamps spaced according to the time difference selected.
	function tsAggregateLinear(this, iTimeDelta, iFunction, ts, ivNumDataOut) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)					:: this
		integer, intent(in)								:: iTimeDelta	! A positive time difference, or TDELTA_YEARMONTH, or TDELTA_YEAR
		integer, intent(in), optional					:: iFunction	! Function code: FUN_MEAN (default), FUN_STDEV, FUN_MIN, FUN_MAX
		type(TimeSeries), intent(out)					:: ts			! The resulting time series
		integer, dimension(:), allocatable, optional	:: ivNumDataOut	! Number of valid data contributing to classes
		integer											:: iRetCode

		! Locals
		integer								:: iErrCode
		integer								:: n
		integer								:: m
		integer								:: i
		integer								:: j
		integer								:: iProcessing
		integer								:: iYear
		integer								:: iMonth
		integer								:: iMinTimeIndex
		type(DateTime)						:: tDateTime
		real(8), dimension(:), allocatable	:: rvTimeStamp
		integer, dimension(:), allocatable	:: ivTimeIndex
		real, dimension(:), allocatable		:: rvValue
		real(8), dimension(:), allocatable	:: rvTimeStamp_Reduced
		integer, dimension(:), allocatable	:: ivNumData
		real, dimension(:), allocatable		:: rvMin
		real, dimension(:), allocatable		:: rvMax
		real, dimension(:), allocatable		:: rvMean
		real, dimension(:), allocatable		:: rvStDev

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be made
		if(this % isEmpty()) then
			iRetCode = 1
			return
		end if

		! Check delta time validity
		if(iTimeDelta == 0) then
			iRetCode = 2
		elseif(iTimeDelta < 0) then
			if(iTimeDelta /= TDELTA_YEARMONTH .and. iTimeDelta /= TDELTA_YEAR) then
				iRetCode = 2
			end if
		end if
		if(iRetCode /= 0) return

		! Retrieve time stamp and data vectors from original time series
		iErrCode = this % getTimeStamp(rvTimeStamp)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		iErrCode = this % getValues(rvValue)
		if(iErrCode /= 0) then
			iRetCode = 4
			deallocate(rvTimeStamp)
			return
		end if
		n = size(rvTimeStamp)

		! Index time, based on the desired time delta
		if(iTimeDelta > 0) then
			allocate(ivTimeIndex(size(rvTimeStamp)))
			where(.valid.rvTimeStamp)
				ivTimeIndex = floor(rvTimeStamp / iTimeDelta) + 1
			elsewhere
				ivTimeIndex = 0
			end where
		else
			select case(iTimeDelta)
			case(TDELTA_YEAR)
				iErrCode = timeGetYear(rvTimeStamp, ivTimeIndex)
			case(TDELTA_YEARMONTH)
				iErrCode = timeGetYearMonth(rvTimeStamp, ivTimeIndex)
			end select
			if(iErrCode /= 0) then
				iRetCode = 5
				deallocate(rvValue)
				deallocate(rvTimeStamp)
				return
			end if
		end if
		if(count(ivTimeIndex > 0) <= 0) then
			iRetCode = 6
			deallocate(rvValue)
			deallocate(rvTimeStamp)
			return
		end if

		! Count maximum index, and use it to reserve workspace
		iMinTimeIndex = minval(ivTimeIndex, mask = ivTimeIndex > 0)
		m = maxval(ivTimeIndex) - iMinTimeIndex + 1
		allocate(rvTimeStamp_Reduced(m), ivNumData(m), rvMin(m), rvMax(m), rvMean(m), rvStDev(m))

		! Change time indicator to a true, 1-based index
		do i = 1, n
			if(ivTimeIndex(i) > 0) then
				ivTimeIndex(i) = ivTimeIndex(i) - iMinTimeIndex + 1
			end if
		end do

		! Form time stamp for new time series; note: 2, not 1, is subtracted
		! from time index. This might sound counter-intuitive, but finds its motivation
		! in the fact that the time index is 1-based (so one 1 to subtract), and
		! j also is (another 1 to subtract). That's is...
		if(iTimeDelta > 0) then
			do j = 1, m
				rvTimeStamp_Reduced(j) = dble((iMinTimeIndex + j - 2)) * iTimeDelta
			end do
		else
			select case(iTimeDelta)
			case(TDELTA_YEAR)
				do j = 1, m
					iYear = iMinTimeIndex + j - 1
					tDateTime = DateTime(iYear, 1, 1, 0, 0, 0.d0)
					rvTimeStamp_Reduced(j) = tDateTime % toEpoch()
				end do
			case(TDELTA_YEARMONTH)
				do j = 1, m
					iMonth = mod(iMinTimeIndex + j - 1, 12) + 1
					iYear  = (iMinTimeIndex + j - 1) / 12
					tDateTime = DateTime(iYear, iMonth, 1, 0, 0, 0.d0)
					rvTimeStamp_Reduced(j) = tDateTime % toEpoch()
				end do
			end select
		end if

		! Update counts
		ivNumData =  0
		rvMin     =  huge(1.)
		rvMax     = -huge(1.)
		rvMean    =  0.
		rvStDev   =  0.
		do i = 1, n
			if((ivTimeIndex(i) > 0) .and. (.valid.rvTimeStamp(i)) .and. (.valid.rvValue(i))) then
				j = ivTimeIndex(i)
				ivNumData(j) = ivNumData(j) + 1
				rvMin(j)     = min(rvMin(j), rvValue(i))
				rvMax(j)     = max(rvMax(j), rvValue(i))
				rvMean(j)    = rvMean(j) + rvValue(i)
				rvStDev(j)   = rvStDev(j) + rvValue(i)**2
			end if
		end do

		! Transform mean and standard deviation counts in nominal quantities.
		! Here I use a little trick, based on non-signalling NaNs: rvMean is computed
		! by specifically discriminating between norman and invalid case. But StDev,
		! on the other side, is computed directly counting on the fact that non
		! signalling NaNs combine algebraically with valid values yielding NaNs
		! (because of IEEE rules).
		where(ivNumData > 0)
			rvMean = rvMean / ivNumData
		elsewhere
			rvMean = NaN
		end where
		rvStDev = sqrt(rvStDev/ivNumData - rvMean**2)

		! Make sure minima and maxima are NaN when class is empty
		where(ivNumData <= 0)
			rvMin = NaN
			rvMax = NaN
		end where

		! Of all quantities computed, transmit (horrible inefficiency) the one desired
		! to the resulting time series
		if(present(iFunction)) then
			iProcessing = iFunction
		else
			iProcessing = FUN_MEAN
		end if
		select case(iFunction)
		case(FUN_MEAN)
			iErrCode = ts % createFromTimeAndDataVectors(rvTimeStamp_Reduced, rvMean)
		case(FUN_STDEV)
			iErrCode = ts % createFromTimeAndDataVectors(rvTimeStamp_Reduced, rvStDev)
		case(FUN_MIN)
			iErrCode = ts % createFromTimeAndDataVectors(rvTimeStamp_Reduced, rvMin)
		case(FUN_MAX)
			iErrCode = ts % createFromTimeAndDataVectors(rvTimeStamp_Reduced, rvMax)
		end select
		if(iErrCode /= 0) then
			iRetCode = 7
		end if

		! Transmit number of data, if desired
		if(present(ivNumDataOut)) then
			if(allocated(ivNumDataOut)) deallocate(ivNumDataOut)
			allocate(ivNumDataOut(size(ivNumData)))
			ivNumDataOut = ivNumData
		end if

		! Leave
		deallocate(rvTimeStamp_Reduced, ivNumData, rvMin, rvMax, rvMean, rvStDev)

	end function tsAggregateLinear


	! Aggregate data of a time series according to a positive time difference,
	! or a negative code indicating time divisions like month and year.
	! Result is a time series, containing the aggregated values and time
	! stamps spaced according to the time difference selected.
	function tsAggregateLinear2( &
		this, iTimeDelta, &
		rvTimeStamp_Reduced, rvMean, &
		rvStDevOut, rvMinOut, rvMaxOut, ivNumDataOut &
	) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)					:: this
		integer, intent(in)								:: iTimeDelta			! A positive time difference, or TDELTA_YEARMONTH, or TDELTA_YEAR
		real(8), dimension(:), allocatable				:: rvTimeStamp_Reduced	! The output time stamp
		real, dimension(:), allocatable					:: rvMean				! Mean value
		real, dimension(:), allocatable, optional		:: rvStDevOut			! Standard deviation
		real, dimension(:), allocatable, optional		:: rvMinOut				! Minimum
		real, dimension(:), allocatable, optional		:: rvMaxOut				! Maximum
		integer, dimension(:), allocatable, optional	:: ivNumDataOut			! Number of valid data contributing to classes
		integer											:: iRetCode

		! Locals
		integer								:: iErrCode
		integer								:: n
		integer								:: m
		integer								:: i
		integer								:: j
		integer								:: iProcessing
		integer								:: iYear
		integer								:: iMonth
		integer								:: iMinTimeIndex
		type(DateTime)						:: tDateTime
		integer, dimension(:), allocatable	:: ivTimeIndex
		real, dimension(:), allocatable		:: rvValue
		real(8), dimension(:), allocatable	:: rvTimeStamp
		integer, dimension(:), allocatable	:: ivNumData
		real, dimension(:), allocatable		:: rvMin
		real, dimension(:), allocatable		:: rvMax
		real, dimension(:), allocatable		:: rvStDev

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be made
		if(this % isEmpty()) then
			iRetCode = 1
			return
		end if

		! Check delta time validity
		if(iTimeDelta == 0) then
			iRetCode = 2
		elseif(iTimeDelta < 0) then
			if(iTimeDelta /= TDELTA_YEARMONTH .and. iTimeDelta /= TDELTA_YEAR) then
				iRetCode = 2
			end if
		end if
		if(iRetCode /= 0) return

		! Retrieve time stamp and data vectors from original time series
		iErrCode = this % getTimeStamp(rvTimeStamp)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		iErrCode = this % getValues(rvValue)
		if(iErrCode /= 0) then
			iRetCode = 4
			deallocate(rvTimeStamp)
			return
		end if
		n = size(rvTimeStamp)

		! Index time, based on the desired time delta
		if(iTimeDelta > 0) then
			allocate(ivTimeIndex(size(rvTimeStamp)))
			where(.valid.rvTimeStamp)
				ivTimeIndex = floor(rvTimeStamp / iTimeDelta) + 1
			elsewhere
				ivTimeIndex = 0
			end where
		else
			select case(iTimeDelta)
			case(TDELTA_YEAR)
				iErrCode = timeGetYear(rvTimeStamp, ivTimeIndex)
			case(TDELTA_YEARMONTH)
				iErrCode = timeGetYearMonth(rvTimeStamp, ivTimeIndex)
			end select
			if(iErrCode /= 0) then
				iRetCode = 5
				deallocate(rvValue)
				deallocate(rvTimeStamp)
				return
			end if
		end if
		if(count(ivTimeIndex > 0) <= 0) then
			iRetCode = 6
			deallocate(rvValue)
			deallocate(rvTimeStamp)
			return
		end if

		! Count maximum index, and use it to reserve workspace
		iMinTimeIndex = minval(ivTimeIndex, mask = ivTimeIndex > 0)
		m = maxval(ivTimeIndex) - iMinTimeIndex + 1
		if(allocated(rvTimeStamp_Reduced)) deallocate(rvTimeStamp_Reduced)
		allocate(rvTimeStamp_Reduced(m))
		if(allocated(rvMean)) deallocate(rvMean)
		allocate(rvMean(m))
		allocate(ivNumData(m), rvMin(m), rvMax(m), rvStDev(m))

		! Change time indicator to a true, 1-based index
		do i = 1, n
			if(ivTimeIndex(i) > 0) then
				ivTimeIndex(i) = ivTimeIndex(i) - iMinTimeIndex + 1
			end if
		end do

		! Form time stamp for new time series; note: 2, not 1, is subtracted
		! from time index. This might sound counter-intuitive, but finds its motivation
		! in the fact that the time index is 1-based (so one 1 to subtract), and
		! j also is (another 1 to subtract). That's is...
		if(iTimeDelta > 0) then
			do j = 1, m
				rvTimeStamp_Reduced(j) = dble((iMinTimeIndex + j - 2)) * iTimeDelta
			end do
		else
			select case(iTimeDelta)
			case(TDELTA_YEAR)
				do j = 1, m
					iYear = iMinTimeIndex + j - 1
					tDateTime = DateTime(iYear, 1, 1, 0, 0, 0.d0)
					rvTimeStamp_Reduced(j) = tDateTime % toEpoch()
				end do
			case(TDELTA_YEARMONTH)
				do j = 1, m
					iMonth = mod(iMinTimeIndex + j - 1, 12) + 1
					iYear  = (iMinTimeIndex + j - 1) / 12
					tDateTime = DateTime(iYear, iMonth, 1, 0, 0, 0.d0)
					rvTimeStamp_Reduced(j) = tDateTime % toEpoch()
				end do
			end select
		end if

		! Update counts
		ivNumData =  0
		rvMin     =  huge(1.)
		rvMax     = -huge(1.)
		rvMean    =  0.
		rvStDev   =  0.
		do i = 1, n
			if((ivTimeIndex(i) > 0) .and. (.valid.rvTimeStamp(i)) .and. (.valid.rvValue(i))) then
				j = ivTimeIndex(i)
				ivNumData(j) = ivNumData(j) + 1
				rvMin(j)     = min(rvMin(j), rvValue(i))
				rvMax(j)     = max(rvMax(j), rvValue(i))
				rvMean(j)    = rvMean(j) + rvValue(i)
				rvStDev(j)   = rvStDev(j) + rvValue(i)**2
			end if
		end do

		! Transform mean and standard deviation counts in nominal quantities.
		! Here I use a little trick, based on non-signalling NaNs: rvMean is computed
		! by specifically discriminating between norman and invalid case. But StDev,
		! on the other side, is computed directly counting on the fact that non
		! signalling NaNs combine algebraically with valid values yielding NaNs
		! (because of IEEE rules).
		where(ivNumData > 0)
			rvMean = rvMean / ivNumData
		elsewhere
			rvMean = NaN
		end where
		rvStDev = sqrt(rvStDev/ivNumData - rvMean**2)

		! Make sure minima and maxima are NaN when class is empty
		where(ivNumData <= 0)
			rvMin = NaN
			rvMax = NaN
		end where

		! Transmit desired quantities
		if(present(rvStDevOut)) then
			if(allocated(rvStDevOut)) deallocate(rvStDevOut)
			allocate(rvStDevOut(size(ivNumData)))
			rvStDevOut = rvStDev
		end if
		if(present(rvMinOut)) then
			if(allocated(rvMinOut)) deallocate(rvMinOut)
			allocate(rvMinOut(size(ivNumData)))
			rvMinOut = rvMin
		end if
		if(present(rvMaxOut)) then
			if(allocated(rvMaxOut)) deallocate(rvMaxOut)
			allocate(rvMaxOut(size(ivNumData)))
			rvMaxOut = rvMax
		end if
		if(present(ivNumDataOut)) then
			if(allocated(ivNumDataOut)) deallocate(ivNumDataOut)
			allocate(ivNumDataOut(size(ivNumData)))
			ivNumDataOut = ivNumData
		end if

		! Leave
		deallocate(ivNumData, rvMin, rvMax, rvStDev, ivTimeIndex)

	end function tsAggregateLinear2

	! Build typical periods (days, months, ...) by applying a periodic aggregation
	function tsAggregatePeriodic( &
		this, iPeriodLength, iTimeDelta, &
		rvMean, &
		rvStDevOut, rvMinOut, rvMaxOut, ivNumDataOut &
	) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(in)					:: this
		integer, intent(in)								:: iPeriodLength		! The length of period considered (positive)
		integer, intent(in)								:: iTimeDelta			! A positive time difference (smaller than period length, and preferably an integer divisor of it)
		real, dimension(:), allocatable					:: rvMean				! Mean value
		real, dimension(:), allocatable, optional		:: rvStDevOut			! Standard deviation
		real, dimension(:), allocatable, optional		:: rvMinOut				! Minimum
		real, dimension(:), allocatable, optional		:: rvMaxOut				! Maximum
		integer, dimension(:), allocatable, optional	:: ivNumDataOut			! Number of valid data contributing to classes
		integer											:: iRetCode

		! Locals
		integer								:: iErrCode
		integer								:: n
		integer								:: m
		integer								:: i
		integer								:: j
		integer								:: iProcessing
		integer								:: iYear
		integer								:: iMonth
		integer								:: iMinTimeIndex
		type(DateTime)						:: tDateTime
		integer, dimension(:), allocatable	:: ivTimeIndex
		real, dimension(:), allocatable		:: rvValue
		real(8), dimension(:), allocatable	:: rvTimeStamp
		integer, dimension(:), allocatable	:: ivNumData
		real, dimension(:), allocatable		:: rvMin
		real, dimension(:), allocatable		:: rvMax
		real, dimension(:), allocatable		:: rvStDev

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be made
		if(this % isEmpty()) then
			iRetCode = 1
			return
		end if

		! Check period and delta time validity
		if(iPeriodLength <= 0) then
			iRetCode = 2
			return
		end if
		if(iTimeDelta <= 0 .or. iTimeDelta > iPeriodLength) then
			iRetCode = 3
			return
		end if

		! Retrieve time stamp and data vectors from original time series
		iErrCode = this % getTimeStamp(rvTimeStamp)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		iErrCode = this % getValues(rvValue)
		if(iErrCode /= 0) then
			iRetCode = 4
			deallocate(rvTimeStamp)
			return
		end if
		n = size(rvTimeStamp)

		! Index time, based on the desired time delta
		iErrCode = timeEncode(rvTimeStamp, iPeriodLength, iTimeDelta, ivTimeIndex)
		if(iErrCode /= 0) then
			iRetCode = 6
			deallocate(rvValue)
			deallocate(rvTimeStamp)
			return
		end if

		! Compute minimum and maximum indices, and use the latter to reserve workspace
		iMinTimeIndex = 1
		m = iPeriodLength / iTimeDelta
		if(allocated(rvMean)) deallocate(rvMean)
		allocate(rvMean(m))
		allocate(ivNumData(m), rvMin(m), rvMax(m), rvStDev(m))

		! Update counts
		ivNumData =  0
		rvMin     =  huge(1.)
		rvMax     = -huge(1.)
		rvMean    =  0.
		rvStDev   =  0.
		do i = 1, n
			if((ivTimeIndex(i) > 0) .and. (.valid.rvTimeStamp(i)) .and. (.valid.rvValue(i))) then
				j = ivTimeIndex(i)
				ivNumData(j) = ivNumData(j) + 1
				rvMin(j)     = min(rvMin(j), rvValue(i))
				rvMax(j)     = max(rvMax(j), rvValue(i))
				rvMean(j)    = rvMean(j) + rvValue(i)
				rvStDev(j)   = rvStDev(j) + rvValue(i)**2
			end if
		end do

		! Transform mean and standard deviation counts in nominal quantities.
		! Here I use a little trick, based on non-signalling NaNs: rvMean is computed
		! by specifically discriminating between norman and invalid case. But StDev,
		! on the other side, is computed directly counting on the fact that non
		! signalling NaNs combine algebraically with valid values yielding NaNs
		! (because of IEEE rules).
		where(ivNumData > 0)
			rvMean = rvMean / ivNumData
		elsewhere
			rvMean = NaN
		end where
		rvStDev = sqrt(rvStDev/ivNumData - rvMean**2)

		! Make sure minima and maxima are NaN when class is empty
		where(ivNumData <= 0)
			rvMin = NaN
			rvMax = NaN
		end where

		! Transmit desired quantities
		if(present(rvStDevOut)) then
			if(allocated(rvStDevOut)) deallocate(rvStDevOut)
			allocate(rvStDevOut(size(ivNumData)))
			rvStDevOut = rvStDev
		end if
		if(present(rvMinOut)) then
			if(allocated(rvMinOut)) deallocate(rvMinOut)
			allocate(rvMinOut(size(ivNumData)))
			rvMinOut = rvMin
		end if
		if(present(rvMaxOut)) then
			if(allocated(rvMaxOut)) deallocate(rvMaxOut)
			allocate(rvMaxOut(size(ivNumData)))
			rvMaxOut = rvMax
		end if
		if(present(ivNumDataOut)) then
			if(allocated(ivNumDataOut)) deallocate(ivNumDataOut)
			allocate(ivNumDataOut(size(ivNumData)))
			ivNumDataOut = ivNumData
		end if

		! Leave
		deallocate(ivNumData, rvMin, rvMax, rvStDev, ivTimeIndex)

	end function tsAggregatePeriodic


	! Create a new time series which is the moving-averaged version of another
	function tsMovingAverage(this, ts, rTimeWidth, iMode) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(out)	:: this			! The time series we want to build
		type(TimeSeries), intent(in)	:: ts			! Time series containing the original data
		real(8), intent(in)				:: rTimeWidth	! Width of the entire time span desired (s)
		integer, intent(in), optional	:: iMode		! MA_ALLDATA (default): use all data; MA_STRICT: use only data with whole left and right sub-intervals
		integer							:: iRetCode

		! Locals
		real(8)								:: rDeltaTime
		real(8), dimension(:), allocatable	:: rvTimeStamp
		real, dimension(:), allocatable		:: rvValue
		real, dimension(:), allocatable		:: rvMeanValue
		integer, dimension(:), allocatable	:: ivNumValid
		integer								:: iFirst, iLast
		integer								:: iFrom, iTo
		integer								:: iNumValues
		integer								:: n, i, j
		integer								:: iWellSpaced
		integer								:: iErrCode
		type(TimeSeries)					:: ts1

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(rTimeWidth <= 0.d0) then
			iRetCode = 1
			return
		end if

		! First of all, check the input time series is well spaced; if it is, but with
		! hidden gaps, make them evident
		iWellSpaced = ts % timeIsWellSpaced(rDeltaTime)
		if(iWellSpaced == 0) then
			iErrCode = ts % getTimeStamp(rvTimeStamp)
			if(iErrCode /= 0) then
				iRetCode = 3
				return
			end if
			iErrCode = ts % getValues(rvValue)
			if(iErrCode /= 0) then
				iRetCode = 4
				return
			end if
		elseif(iWellSpaced == 1) then
			iErrCode = ts1 % CreateFromTimeSeries(ts, .true.)
			if(iErrCode /= 0) then
				iRetCode = 2
				return
			end if
			iErrCode = ts1 % getTimeStamp(rvTimeStamp)
			if(iErrCode /= 0) then
				iRetCode = 3
				return
			end if
			iErrCode = ts1 % getValues(rvValue)
			if(iErrCode /= 0) then
				iRetCode = 4
				return
			end if
		elseif(iWellSpaced < 0 .or. iWellSpaced > 1) then
			iRetCode = 5
			return
		end if
		if(size(rvTimeStamp) < 1) then
			iRetCode = 6
			deallocate(rvTimeStamp, rvValue)
			return
		end if
		! Post-condition: rvTimeStamp and rvValue both allocated, and with at least one element;
		!                 additionally, rvTimeStamp is well-spaced and monotonic, and the rvValue
		! vector "may" contain gaps.

		! Convert time width in the number of items to take before and after the current
		! time series element. If it is zero or less, copy the input series as it is
		n = size(rvTimeStamp)
		iNumValues = floor(rTimeWidth / (2.*rDeltaTime))
		if(iNumValues < 1) then
			if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
			if(allocated(this % rvValue))     deallocate(this % rvValue)
			allocate(this % rvTimeStamp(size(rvTimeStamp)))
			allocate(this % rvValue(size(rvValue)))
			this % rvTimeStamp = rvTimeStamp
			this % rvValue     = rvValue
			deallocate(rvTimeStamp, rvValue)
			return
		end if

		! Set initial and final indices to consider
		if(present(iMode)) then
			if(iMode == MA_STRICT) then
				iFirst = 1 + iNumValues
				iLast  = n - iNumValues
				if(iFirst >= iLast) then
					iRetCode = 7
					deallocate(rvTimeStamp, rvValue)
					return
				end if
			elseif(iMode == MA_ALLDATA) then
				iFirst = 1
				iLast  = n
			else
				iRetCode = 7
				deallocate(rvTimeStamp, rvValue)
				return
			end if
		else	! Default: MA_ALLDATA
			iFirst = 1
			iLast  = n
		end if

		! Compute the desired time series, taking into account
		! the number of valid values in averaging
		allocate(ivNumValid(iLast-iFirst+1), rvMeanValue(iLast-iFirst+1))
		j = 1
		do i = iFirst, iLast
			iFrom = max(i - iNumValues, 1)
			iTo   = min(i + iNumValues, n)
			ivNumValid(j) = count(.valid.rvValue(iFrom:iTo))
			if(ivNumValid(j) > 0) then
				rvMeanValue(j) = sum(rvValue(iFrom:iTo), mask = .valid.rvValue(iFrom:iTo)) / ivNumValid(j)
			else
				rvMeanValue(j) = NaN
			end if
			j = j + 1
		end do

		! Fill current series with new averaged values
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue))     deallocate(this % rvValue)
		allocate(this % rvTimeStamp(size(rvTimeStamp)))
		allocate(this % rvValue(size(rvValue)))
		this % rvTimeStamp = rvTimeStamp(iFirst:iLast)
		this % rvValue     = rvMeanValue

	end function tsMovingAverage


	! Create a new time series which is the moving-stddev of another
	function tsMovingStdDev(this, ts, rTimeWidth, iMode) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(out)	:: this			! The time series we want to build
		type(TimeSeries), intent(in)	:: ts			! Time series containing the original data
		real(8), intent(in)				:: rTimeWidth	! Width of the entire time span desired (s)
		integer, intent(in), optional	:: iMode		! MA_ALLDATA (default): use all data; MA_STRICT: use only data with whole left and right sub-intervals
		integer							:: iRetCode

		! Locals
		real(8)								:: rDeltaTime
		real(8), dimension(:), allocatable	:: rvTimeStamp
		real, dimension(:), allocatable		:: rvValue
		real, dimension(:), allocatable		:: rvMeanValue
		real, dimension(:), allocatable		:: rvMeanSquaredValue
		integer, dimension(:), allocatable	:: ivNumValid
		integer								:: iFirst, iLast
		integer								:: iFrom, iTo
		integer								:: iNumValues
		integer								:: n, i, j
		integer								:: iWellSpaced
		integer								:: iErrCode
		type(TimeSeries)					:: ts1

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(rTimeWidth <= 0.d0) then
			iRetCode = 1
			return
		end if

		! First of all, check the input time series is well spaced; if it is, but with
		! hidden gaps, make them evident
		iWellSpaced = ts % timeIsWellSpaced(rDeltaTime)
		if(iWellSpaced == 0) then
			iErrCode = ts % getTimeStamp(rvTimeStamp)
			if(iErrCode /= 0) then
				iRetCode = 3
				return
			end if
			iErrCode = ts % getValues(rvValue)
			if(iErrCode /= 0) then
				iRetCode = 4
				return
			end if
		elseif(iWellSpaced == 1) then
			iErrCode = ts1 % CreateFromTimeSeries(ts, .true.)
			if(iErrCode /= 0) then
				iRetCode = 2
				return
			end if
			iErrCode = ts1 % getTimeStamp(rvTimeStamp)
			if(iErrCode /= 0) then
				iRetCode = 3
				return
			end if
			iErrCode = ts1 % getValues(rvValue)
			if(iErrCode /= 0) then
				iRetCode = 4
				return
			end if
		elseif(iWellSpaced < 0 .or. iWellSpaced > 1) then
			iRetCode = 5
			return
		end if
		if(size(rvTimeStamp) < 1) then
			iRetCode = 6
			deallocate(rvTimeStamp, rvValue)
			return
		end if
		! Post-condition: rvTimeStamp and rvValue both allocated, and with at least one element;
		!                 additionally, rvTimeStamp is well-spaced and monotonic, and the rvValue
		! vector "may" contain gaps.

		! Convert time width in the number of items to take before and after the current
		! time series element. If it is zero or less, copy the input series as it is
		n = size(rvTimeStamp)
		iNumValues = floor(rTimeWidth / (2.*rDeltaTime))
		if(iNumValues < 1) then
			if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
			if(allocated(this % rvValue))     deallocate(this % rvValue)
			allocate(this % rvTimeStamp(size(rvTimeStamp)))
			allocate(this % rvValue(size(rvValue)))
			this % rvTimeStamp = rvTimeStamp
			this % rvValue     = rvValue
			deallocate(rvTimeStamp, rvValue)
			return
		end if

		! Set initial and final indices to consider
		if(present(iMode)) then
			if(iMode == MA_STRICT) then
				iFirst = 1 + iNumValues
				iLast  = n - iNumValues
				if(iFirst >= iLast) then
					iRetCode = 7
					deallocate(rvTimeStamp, rvValue)
					return
				end if
			elseif(iMode == MA_ALLDATA) then
				iFirst = 1
				iLast  = n
			else
				iRetCode = 7
				deallocate(rvTimeStamp, rvValue)
				return
			end if
		else	! Default: MA_ALLDATA
			iFirst = 1
			iLast  = n
		end if

		! Compute the desired time series, taking into account
		! the number of valid values in averaging
		allocate(ivNumValid(iLast-iFirst+1), rvMeanValue(iLast-iFirst+1), rvMeanSquaredValue(iLast-iFirst+1))
		j = 1
		do i = iFirst, iLast
			iFrom = max(i - iNumValues, 1)
			iTo   = min(i + iNumValues, n)
			ivNumValid(j) = count(.valid.rvValue(iFrom:iTo))
			if(ivNumValid(j) > 0) then
				rvMeanValue(j)        = sum(rvValue(iFrom:iTo), mask = .valid.rvValue(iFrom:iTo)) / ivNumValid(j)
				rvMeanSquaredValue(j) = sum(rvValue(iFrom:iTo)**2, mask = .valid.rvValue(iFrom:iTo)) / ivNumValid(j)
			else
				rvMeanValue(j)        = NaN
				rvMeanSquaredValue(j) = NaN
			end if
			j = j + 1
		end do

		! Fill current series with new averaged values
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvValue))     deallocate(this % rvValue)
		allocate(this % rvTimeStamp(size(rvTimeStamp)))
		allocate(this % rvValue(size(rvValue)))
		this % rvTimeStamp = rvTimeStamp(iFirst:iLast)
		this % rvValue     = sqrt(rvMeanSquaredValue - rvMeanValue**2)

	end function tsMovingStdDev


	function tsFillGaps(this, iDaysRadius, lvOriginal) result(iRetCode)

		! Routine arguments
		class(TimeSeries), intent(inout)				:: this			! The time series we want to gap-fill
		integer, intent(in)								:: iDaysRadius
		logical, dimension(:), allocatable, intent(out)	:: lvOriginal
		integer											:: iRetCode

		! Locals
		integer								:: iErrCode
		integer								:: iNumItemsPerDay
		integer								:: iNumDays
		integer								:: iCurDay
		integer								:: i
		real(8)								:: rDeltaTime
		integer								:: iIsWellSpaced
		integer								:: iNumData
		integer								:: iNumGaps
		real(8)								:: rBaseDay
		real(8)								:: rWindowBegin
		real(8)								:: rWindowEnd
		integer, dimension(:), allocatable	:: ivNumValues
		logical, dimension(:), allocatable	:: lvCurDay
		integer, dimension(:), allocatable	:: ivTimeIndex
		real(8), dimension(:), allocatable	:: rvSumValues

		! Constants
		real(8), parameter	:: ONE_HOUR = 3600.d0
		real(8), parameter	:: ONE_DAY  = 24*ONE_HOUR

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check parameters
		if(this % isEmpty()) then
			iRetCode = 1
			return
		end if
		iIsWellSpaced = this % timeIsWellSpaced(rDeltaTime, iNumGaps)
		if(iIsWellSpaced /= 0) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		iNumData = size(this % rvTimeStamp)
		if(allocated(lvOriginal)) deallocate(lvOriginal)
		allocate(lvOriginal(iNumData))
		allocate(lvCurDay(iNumData))

		! How many data come in a day?
		if(rDeltaTime <= 0.d0) then
			iRetCode = 2
			return
		end if
		iNumItemsPerDay = floor(ONE_DAY / rDeltaTime)

		! How many days in data set?
		rBaseDay = timeFloorDay(this % rvTimeStamp(1))
		iNumDays = floor((timeFloorDay(this % rvTimeStamp(iNumData)) - rBaseDay + ONE_DAY) / ONE_DAY) + 1
		if(iNumDays <= 0) then
			iRetCode = 3
			return
		end if

		! Reserve temporary workspace
		allocate(ivNumValues(iNumItemsPerDay), rvSumValues(iNumItemsPerDay), STAT=iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 4
			return
		end if
		rvSumValues = 0.
		ivNumValues = 0

		! Encode time to typical-day index
		iErrCode = timeEncode(this % rvTimeStamp, int(ONE_DAY, kind=4), int(rDeltaTime, kind=4), ivTimeIndex)
		if(iErrCode /= 0) then
			iRetCode = 5
			return
		end if

		! Iterate over days
		do iCurDay = 1, iNumDays

			! Delimit day
			rWindowBegin = rBaseDay
			rWindowEnd   = rWindowBegin + ONE_DAY
			lvCurDay     = this % rvTimeStamp >= rWindowBegin .and. this % rvTimeStamp <= rWindowEnd

			! Check whether something is to be made on this day
			iNumGaps = count((.invalid.this % rvValue) .and. lvCurDay)
			if(iNumGaps > 0) then

				! Update counters for the typical day
				rWindowBegin = rBaseDay + (iCurDay-1)*ONE_DAY - iDaysRadius*ONE_DAY
				rWindowEnd   = rBaseDay + (iCurDay-1)*ONE_DAY + (iDaysRadius+1)*ONE_DAY
				do i = 1, size(this % rvTimeStamp)
					if(this % rvTimeStamp(i) >= rWindowBegin .and. this % rvTimeStamp(i) <= rWindowEnd) then
						if(ivTimeIndex(i) > 0) then
							ivNumValues(ivTimeIndex(i)) = ivNumValues(ivTimeIndex(i)) + 1
							rvSumValues(ivTimeIndex(i)) = rvSumValues(ivTimeIndex(i)) + this % rvValue(i)
						end if
					end if
				end do

				! Render the typical day

			end if

		end do

		! Leave
		deallocate(ivNumValues, rvSumValues)
		deallocate(lvCurDay)

	end function tsFillGaps


	function dfClean(this) result(iRetCode)

		! Routine arguments
		class(TwoDimensionalField), intent(out)	:: this
		integer									:: iRetCode

		! Locals
		! --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Reclaim workspace, if any
		if(allocated(this % rmValue))       deallocate(this % rmValue)
		if(allocated(this % rvX))           deallocate(this % rvX)
		if(allocated(this % rvY))           deallocate(this % rvY)
		if(allocated(this % imNumAdjacent)) deallocate(this % imNumAdjacent)
		if(allocated(this % iaAdjacent))    deallocate(this % iaAdjacent)
		if(allocated(this % raDistance))    deallocate(this % raDistance)

	end function dfClean


	function dfInitialize(this, rXsw, rYsw, rDx, rDy, iNx, iNy, rvX, rvY, rThreshold) result(iRetCode)

		! Routine arguments
		class(TwoDimensionalField), intent(inout)	:: this
		real(8), intent(in)							:: rXsw
		real(8), intent(in)							:: rYsw
		real(8), intent(in)							:: rDx
		real(8), intent(in)							:: rDy
		integer, intent(in)							:: iNx
		integer, intent(in)							:: iNy
		real, dimension(:), intent(in)				:: rvX
		real, dimension(:), intent(in)				:: rvY
		real(8), intent(in)							:: rThreshold
		integer										:: iRetCode

		! Locals
		integer		:: iErrCode
		integer		:: i, j, k
		integer		:: n, m

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Clean workspace
		iErrCode = this % clean()
		if(iErrCode /= 0) then
			iRetCode = 1
			return
		end if

		! Check parameters
		if(.not.(.valid.rXsw) .or. .not.(.valid.rYsw)) then
			iRetCode = 2
			return
		end if
		if(iNx <= 0 .or. iNy <= 0) then
			iRetCode = 2
			return
		end if
		if(rDx <= 0.d0 .or. rDy <= 0.d0) then
			iRetCode = 2
			return
		end if

		! Check the input data make some sense
		if(size(rvX) <= 0 .or. size(rvY) <= 0) then
			iRetCode = 3
			return
		end if
		if(size(rvX) /= size(rvY)) then
			iRetCode = 4
			return
		end if
		if(any(.invalid.rvX) .or. any(.invalid.rvY)) then
			iRetCode = 5
			return
		end if
		n = size(rvX)	! Which is, by the preceding tests, the same as size(rvY)
		if(rThreshold <= 0.d0) then
			iRetCode = 6
			return
		end if

		! Reserve workspace
		allocate(this % rmValue(iNx, iNy))
		allocate(this % rvX(iNx))
		allocate(this % rvY(iNy))
		allocate(this % imNumAdjacent(iNx, iNy))
		allocate(this % iaAdjacent(n, iNx, iNy))
		allocate(this % raDistance(n, iNx, iNy))

		! Fill workspace
		this % rmValue = 0.d0
		this % rvX     = [(rXsw + rDx * (i-1), i=1,iNx)]
		this % rvY     = [(rYsw + rDy * (i-1), i=1,iNy)]

		! Build the distance matrix
		allocate(this % raDistance(n, iNx, iNy))
		do k = 1, iNy
			do j = 1, iNx
				do i = 1, n
					this % raDistance(i,j,k) = sqrt((rvX(i) - this % rvX(j))**2 + (rvY(i) - this % rvY(k))**2)
				end do
			end do
		end do

		! Compare to distance threshold and build the adjacency lists
		do k = 1, iNy
			do j = 1, iNx
				m = 0
				do i = 1, n
					if(this % raDistance(i,j,k) >= rThreshold) then
						m = m + 1
						this % imNumAdjacent(j,k)  = m
						this % iaAdjacent(m, j, k) = i
					end if
				end do
			end do
		end do

		! Check some grid point is not covered by at least one experimental point
		if(any(this % imNumAdjacent <= 0)) then
			iRetCode = 7
			return
		end if
		! Post-condition: we have distances, and adjacency lists: success

	end function dfInitialize


	function dfEvaluate(this, rvValue) result(iRetCode)

		! Routine arguments
		class(TwoDimensionalField), intent(inout)	:: this
		real, dimension(:), intent(in)				:: rvValue
		integer										:: iRetCode

		! Locals
		integer		:: iErrCode
		integer		:: iNx
		integer		:: iNy

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check the 2D field to make some sense
		if(.not.allocated(this % rmValue) .or. .not.allocated(this % rvX) .or. .not.allocated(this % rvY)) then
			iRetCode = 1
			return
		end if
		if(size(this % rvX) <= 0 .or. size(this % rvY) <= 0) then
			iRetCode = 2
			return
		end if

		! Generate weights


	end function dfEvaluate

	! *********************
	! * Internal routines *
	! *********************

	! quicksort.f -*-f90-*-
	! Author: t-nissie, some tweaks by 1AdAstra1, and some others by Mauri Favaron
	! License: GPLv3
	! Gist: https://gist.github.com/t-nissie/479f0f16966925fa29ea
	!
	recursive subroutine quicksort(a)

		! Routine arguments
		real, dimension(:), intent(inout)	:: a

		! Locals
		real	:: x, t
		integer :: first = 1, last
		integer :: i, j

		! Initialization
		last = size(a)
		if(last <= 1) return	! Nothing to do
		x = a( (first+last) / 2 )
		i = first
		j = last

		! Exploration phase
		do
			do while (a(i) < x)
				i=i+1
			end do
			do while (x < a(j))
				j=j-1
			end do
			if (i >= j) exit
			t = a(i);  a(i) = a(j);  a(j) = t
			i=i+1
			j=j-1
		end do

		! Recursion phase
		if (first < i - 1) call quicksort(a(first : i - 1))
		if (j + 1 < last)  call quicksort(a(j + 1 : last))

	end subroutine quicksort


	! Computes the rank index of an array
	recursive subroutine quicksort_idx_4(a, idx)

		! Routine arguments
		real, dimension(:), intent(inout)		:: a	! On entry the vector to sort
		integer, dimension(:), intent(inout)	:: idx	! On entry, the identity permutation denoted as [1, 2, 3, ..., n]

		! Locals
		real	:: x, t
		integer :: first = 1, last
		integer :: i, j
		integer	:: iHold

		! Initialization
		last = size(a)
		if(last <= 1) return	! Nothing to do
		x = a( (first+last) / 2 )
		i = first
		j = last

		! Exploration phase
		do
			do while (a(i) < x)
				i=i+1
			end do
			do while (x < a(j))
				j=j-1
			end do
			if (i >= j) exit
			t = a(i);  a(i) = a(j);  a(j) = t
			iHold = idx(i); idx(i) = idx(j); idx(j) = iHold
			i=i+1
			j=j-1
		end do

		! Recursion phase
		if (first < i - 1) call quicksort_idx_4(a(first : i - 1), idx(first : i - 1))
		if (j + 1 < last)  call quicksort_idx_4(a(j + 1 : last), idx(j + 1 : last))

	end subroutine quicksort_idx_4


	! Computes the rank index of an array
	recursive subroutine quicksort_idx_8(a, idx)

		! Routine arguments
		real(8), dimension(:), intent(inout)	:: a	! On entry the vector to sort
		integer, dimension(:), intent(inout)	:: idx	! On entry, the identity permutation denoted as [1, 2, 3, ..., n]

		! Locals
		real(8)	:: x, t
		integer :: first = 1, last
		integer :: i, j
		integer	:: iHold

		! Initialization
		last = size(a)
		if(last <= 1) return	! Nothing to do
		x = a( (first+last) / 2 )
		i = first
		j = last

		! Exploration phase
		do
			do while (a(i) < x)
				i=i+1
			end do
			do while (x < a(j))
				j=j-1
			end do
			if (i >= j) exit
			t = a(i);  a(i) = a(j);  a(j) = t
			iHold = idx(i); idx(i) = idx(j); idx(j) = iHold
			i=i+1
			j=j-1
		end do

		! Recursion phase
		if (first < i - 1) call quicksort_idx_8(a(first : i - 1), idx(first : i - 1))
		if (j + 1 < last)  call quicksort_idx_8(a(j + 1 : last), idx(j + 1 : last))

	end subroutine quicksort_idx_8

end module pbl_stat


! pbl_thermo - Fortran module, containing computations related to
!              Planetary Boundary Layer (PBL) quantities, encompassing
! the lower atmosphere thermodynamics, energy balance, psychrometry,
! and some astronomical formulae dealing with sunset/sunrise and apparent
! solar position.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_thermo

	use ieee_arithmetic
	use pbl_base
	use pbl_time

	implicit none

	private

	! Public interface
	! 1. Thermodynamics and psychrometry
	PUBLIC	:: WaterSaturationPressure		! Saturation vapor pressure at a given temperature
	PUBLIC	:: E_SAT_1						! Saturation water vapor pressure, from old PBL_MET
	PUBLIC	:: D_E_SAT						! Derivative of saturation water vapor pressure, from old PBL_MET
	PUBLIC	:: PrecipitableWater			! Estimate the amount of precipitable water
	PUBLIC	:: WaterVaporPressure			! Water vapor partial pressure
	PUBLIC	:: RelativeHumidity				! Relative humidity
	PUBLIC	:: AbsoluteHumidity				! Absolute humidity (i.e. density of water vapor in air)
	PUBLIC	:: AirDensity					! Density of air, given temperature and pressure
	PUBLIC	:: RhoCp						! Product of air density and constant pressure thermal capacity of air
	PUBLIC	:: LatentVaporizationHeat		! Latent vaporization heat at given temperature
	PUBLIC	:: DewPointTemperature			! Approximate dew point temperature
	PUBLIC	:: WetBulbTemperature			! Wet bulb temperature estimate, given dry bulb temperature, relative humidity and pressure
	PUBLIC	:: AirPressure					! Estimate atmospheric pressure from height and temperature
	PUBLIC	:: VirtualTemperature			! Virtual temperature given water vapor pressure and air pressure
	PUBLIC	:: SonicTemperature				! Estimate ultrasonic temperature given dry bulb temperature, relative humidity and pressure
	! 2. Energy balance at ground-atmosphere contact (new method, as from ASCE Evapotranspiration Equation
 	public	:: ClearSkyRg_Simple			! Simple estimate of global solar radiation under clear sky conditions
	public	:: ClearSkyRg_Accurate			! More accurate estimate of global solar radiation under clear sky conditions
	public	:: ExtraterrestrialRadiation	! Estimate of extraterrestrial radiation (i.e., global radiation above the Earth atmosphere)
	public	:: NetRadiation					! Estimate of solar net radiation
	public	:: Cloudiness					! Estimate cloudiness factor (see ASCE report for definitions)
	! 3. Energy balance at ground atmosphere contact (old PBL_MET method)
	public	:: GlobalRadiation_MPDA			! Supersedes SUN_RAD2 in old PBL_MET
	public	:: CloudCover_MPDA				! Supersedes CLOUD_RG in old PBL_MET
	public	:: NetRadiation_MPDA			! Supersedes R_NET_D and R_NET_N in ECOMET legacy code
	! 4. Atmospheric scaling quantities
	public	:: BruntVaisala					! Estimate of Brunt-Vaisala frequency, given temperature and height

	! Polymorphic (Fortran-90-art) routines

	interface AirPressure
		module procedure AirPressure1
		module procedure AirPressure2
	end interface AirPressure

	interface AirDensity
	    module procedure AirDensity_4
	    module procedure AirDensity_8
	end interface AirDensity

	interface RhoCp
	    module procedure RhoCp_4
	    module procedure RhoCp_8
	end interface RhoCp

contains

	! Estimation of clear sky radiation by the simplified method
	!
	! Input:
	!
	!	Ra		Extraterrestrial radiation (W/m2)
	!
	!	z		Site elevation above mean sea level (m)
	!
	! Output:
	!
	!	Rso		Clear sky radiation (W/m2)
	!
	function ClearSkyRg_Simple(Ra, z) result(Rso)

		implicit none

		! Routine arguments
		real, intent(in)	:: Ra
		real, intent(in)	:: z
		real				:: Rso

		! Locals
		! -none-

		! Compute the information item desired
		Rso = Ra * (0.75 + 2.0e-5*z)

	end function ClearSkyRg_Simple


	! Estimation of clear sky radiation by the extended, more accurate method
	!
	! Input:
	!
	!	timeStamp			String, in form "YYYY-MM-DD HH:MM:SS" indicating time on *beginning* of averaging period
	!						(beware: many Italian weather station use a time stamp on *end* of averaging period:
	!						if so, subtract one hour)
	!
	!	averagingPeriod		Length of averaging period (s)
	!
	!	lat					Local latitude (degrees, positive northwards)
	!
	!	lon					Local longitude (degrees, positive eastwards)
	!
	!	zone				Time zone number (hours, positive Eastwards, in range -12 to 12)
	!
	!	Pa					Local pressure, that is, pressure not reduced to mean sea level (hPa)
	!
	!	Temp				Local temperature (Celsius degrees)
	!
	!	Hrel				Relative humidity (%)
	!
	!	Kt					Turbidity coefficient (dimensionless, 0 excluded to 1 included;
	!						value 1 corresponds to perfectly clean air; for extremelyturbid,
	!						dusty or polluted air 0.5 may be assumed; recommended value lacking
	!						better data: 1, the default)
	!
	! Output:
	!
	!	Rso					Clear sky radiation (W/m2)
	!
	function ClearSkyRg_Accurate(timeStamp, averagingPeriod, lat, lon, zone, Pa, Temp, Hrel, Kt_In) result(Rso)

		implicit none

		! Routine arguments
		character(len=*), intent(in)	:: timeStamp
		real, intent(in)				:: averagingPeriod, lat, lon, zone, Pa, Temp, Hrel
		real, intent(in), optional		:: Kt_In
		real							:: Rso

		! Locals
		real	:: Kt

		real	:: Kb, Kd, Ra
		real	:: beta, sinBeta, W
		real	:: e, es, Ta
		integer	:: ss, mm, hh, yy, mo, dy, iDayOfYear
		real	:: dr
		real	:: omega, omega1, omega2, omegaS
		real	:: timenow, JD, t, Sc, b, t1
		real	:: solarDeclination, centralMeridianLongitude, localLongitude
		real	:: delta_lon, intermediate, sign
		integer	:: iErrCode

		! Constants
		real, parameter	:: SOLAR_CONSTANT = 1.e6*49.2/3600.0		! W/m2
		real, parameter	:: PI             = 3.1415927

		! Get optional parameter (assign default if missing)
		if(present(Kt_In)) then
			Kt = Kt_In
		else
			Kt = 1.0
		end if

		! get date and time
		read(timeStamp, "(i4,5(1x,i2))", iostat=iErrCode) yy, mo, dy, hh, mm, ss
		if(iErrCode /= 0) then
			Rso = NaN
			return
		end if
		iDayOfYear = DoY(yy,mo,dy)

		! Compute solar declination
		solarDeclination = 0.409*SIN(2*PI/365*iDayOfYear - 1.39)

		! Compute Julian day
		timenow = hh + mm/60.0 + ss/3600.0 - zone
		JD = calcJD(yy, mo, dy)

		! Inverse squared relative distance factor for Sun-Earth
		dr = 1.0 + 0.033*COS(2*PI*iDayOfYear/365.0)

		! Calculate geographical positioning parameters (with a "-" sign for longitudes, according to ASCE conventions)
		centralMeridianLongitude = -zone*15.0
		if(centralMeridianLongitude < 0.0) then
			centralMeridianLongitude = centralMeridianLongitude + 360.0
		end if
		localLongitude = -lon
		if(localLongitude < 0.0) then
			localLongitude = localLongitude + 360.0
		end if

		! Compute hour at mid of averaging time
		t1 = averagingPeriod / 3600.0
		t = timenow + zone + 0.5*t1

		! Calculate seasonal correction for solar time
		b  = 2.*PI*(iDayOfYear-81)/364.0
		Sc = 0.1645*SIN(2.0*b) - 0.1255*COS(b) - 0.025*SIN(b)

		! Solar time angle at midpoint of averaging time
		delta_lon = MOD(ABS(centralMeridianLongitude - localLongitude), 360.0)
		if(delta_lon > 180.0) then
			intermediate = 360.0 - delta_lon
		else
			intermediate = delta_lon
		end if
		if(((delta_lon > 0.0) .and. (delta_lon <= 180.0)) .or. ((delta_lon <= -180.0) .and. (delta_lon >= -360.0))) then
			sign =  1.0
		else
			sign = -1.0
		end if
		delta_lon = sign * intermediate
		omega = (PI/12.0) * ((t + 0.06667*(delta_lon) + Sc) - 12.0)

		! Solar time angle at beginning and end of averaging period
		omega1 = omega - PI*t1/24.0
		omega2 = omega + PI*t1/24.0

		! Adjust angular end points to exclude nighttime hours
		omegaS = ACOS(-TAN(lat*PI/180.0)*TAN(solarDeclination))	! Sunset angle
		if(omega1 < -omegaS) then
			omega1 = -omegaS
		end if
		if(omega2 < -omegaS) then
			omega2 = -omegaS
		end if
		if(omega1 > omegaS) then
			omega1 = omegaS
		end if
		if(omega2 > omegaS) then
			omega2 = omegaS
		end if
		if(omega1 > omega2) then
			omega1 = omega2
		end if

		! Compute extraterrestrial radiation
		Ra = 12/PI * SOLAR_CONSTANT * dr * ( &
				(omega2-omega1)*SIN(lat*PI/180.0)*SIN(solarDeclination) + &
				COS(lat*PI/180.0)*COS(solarDeclination)*(SIN(omega2) - SIN(omega1)) &
		)

		! Estimate the amount of precipitable water
		Ta = Temp + 273.15
		es = E_SAT_1(Temp)
		e  = Hrel*es/100.0
		W  = PrecipitableWater(e, Pa)

		! Compute solar elevation (refractive correction is not applied, in compliance with ASCE standard evapotranspiration equation)
		sinBeta = SIN(lat*PI/180.0)*SIN(solarDeclination) + COS(lat*PI/180.0)*COS(solarDeclination)*COS(omega)
		if(sinBeta > 0.0) then

			! Estimate the clearness index for direct beam radiation
			Kb = 0.98*EXP(-0.000149*Pa/(Kt*sinBeta) - 0.075*(W/sinBeta)**0.4)

			! Estimate the transmissivity index for diffuse radiation
			if(Kb >= 0.15) then
				Kd = 0.35 - 0.36*Kb
			else
				Kd = 0.18 + 0.82*Kb
			end if

		else

			! Assume null clearness and transmissivity on night-time
			Kb = 0.0
			Kd = 0.18

		end if

		! Last, estimate clear-sky radiation
		Rso = Ra * (Kb + Kd)

	end function ClearSkyRg_Accurate


	! Accurate estimate of extraterrestrial solar radiation
	!
	! Input:
	!
	!	timeStamp			String, in form "YYYY-MM-DD HH:MM:SS" indicating time on *beginning* of averaging period
	!						(beware: many Italian weather station use a time stamp on *end* of averaging period:
	!						if so, subtract one hour)
	!
	!	averagingPeriod		Length of averaging period (s)
	!
	!	lat					Local latitude (degrees, positive northwards)
	!
	!	lon					Local longitude (degrees, positive eastwards)
	!
	!	zone				Time zone number (hours, positive Eastwards, in range -12 to 12)
	!
	! Output:
	!
	!	ra					Extraterrestrial radiation (W/m2)
	!
	function ExtraterrestrialRadiation(timeStamp, averagingPeriod, lat, lon, zone) result(ra)

		implicit none

		! Routine arguments
		character(len=*), intent(in)	:: timeStamp
		real, intent(in)				:: averagingPeriod, lat, lon, zone
		real							:: ra

		! Locals
		integer	:: iErrCode
		integer	:: ss, mm, hh, yy, mo, dy, iDayOfYear
		real	:: dr
		real	:: omega, omega1, omega2, omegaS
		real	:: timenow, JD, t, Sc, b, t1
		real	:: solarDeclination, centralMeridianLongitude, localLongitude
		real	:: delta_lon, intermediate, sign

		! Constants
		real, parameter	:: SOLAR_CONSTANT = 1.e6*49.2/3600.0		! W/m2
		real, parameter	:: PI             = 3.1415927

		! Get date and time
		read(timeStamp, "(i4,5(1x,i2))", iostat=iErrCode) yy, mo, dy, hh, mm, ss
		if(iErrCode /= 0) then
			Ra = NaN
			return
		end if
		iDayOfYear = DoY(yy,mo,dy)

		! Compute solar declination
		solarDeclination = 0.409*SIN(2*PI/365*iDayOfYear - 1.39)

		! Compute Julian day
		timenow = hh + mm/60.0 + ss/3600.0 - zone
		JD = calcJD(yy, mo, dy)

		! Inverse squared relative distance factor for Sun-Earth
		dr = 1.0 + 0.033*COS(2*PI*iDayOfYear/365.0)

		! Calculate geographical positioning parameters (with a "-" sign for longitudes, according to ASCE conventions)
		centralMeridianLongitude = -zone*15.0
		if(centralMeridianLongitude < 0.0) then
			centralMeridianLongitude = centralMeridianLongitude + 360.0
		end if
		localLongitude = -lon
		if(localLongitude < 0.0) then
			localLongitude = localLongitude + 360.0
		end if

		! Compute hour at mid of averaging time
		t1 = averagingPeriod / 3600.0
		t = timenow + zone + 0.5*t1

		! Calculate seasonal correction for solar time
		b  = 2.*PI*(iDayOfYear-81)/364.0
		Sc = 0.1645*SIN(2.0*b) - 0.1255*COS(b) - 0.025*SIN(b)

		! Solar time angle at midpoint of averaging time
		delta_lon = MOD(ABS(centralMeridianLongitude - localLongitude), 360.0)
		if(delta_lon > 180.0) then
			intermediate = 360.0 - delta_lon
		else
			intermediate = delta_lon
		end if
		if(((delta_lon > 0.0) .and. (delta_lon <= 180.0)) .or. ((delta_lon <= -180.0) .and. (delta_lon >= -360.0))) then
			sign =  1.0
		else
			sign = -1.0
		end if
		delta_lon = sign * intermediate
		omega = (PI/12.0) * ((t + 0.06667*(delta_lon) + Sc) - 12.0)

		! Solar time angle at beginning and end of averaging period
		omega1 = omega - PI*t1/24.0
		omega2 = omega + PI*t1/24.0

		! Adjust angular end points to exclude nighttime hours
		omegaS = ACOS(-TAN(lat*PI/180.0)*TAN(solarDeclination))	! Sunset angle
		if(omega1 < -omegaS) then
			omega1 = -omegaS
		end if
		if(omega2 < -omegaS) then
			omega2 = -omegaS
		end if
		if(omega1 > omegaS) then
			omega1 = omegaS
		end if
		if(omega2 > omegaS) then
			omega2 = omegaS
		end if
		if(omega1 > omega2) then
			omega1 = omega2
		end if

		! Compute extraterrestrial radiation
		ra = 12/PI * SOLAR_CONSTANT * dr * ( &
				(omega2-omega1)*SIN(lat*PI/180.0)*SIN(solarDeclination) + &
				COS(lat*PI/180.0)*COS(solarDeclination)*(SIN(omega2) - SIN(omega1)) &
			)

		! Clip to interval [0,+infinity), as radiation cannot be negative
		ra = max(ra, 0.)

	end function ExtraterrestrialRadiation


	! Estimation of net radiation not using cloud cover, as from ASCE standardized reference evapotranspiration equation.
	!
	! Input:
	!
	!	Rg		Measured or estimated global radiation (W/m2)
	!
	!	albedo	Albedo at site (dimensionless)
	!
	!	fcd		Cloudiness function (dimensionless, 0 to 1)
	!
	!	Ea		Water vapor pressure (hPa)
	!
	!	Ta		Air temperature (K)
	!
	! Output:
	!
	!	Rn		Net radiation (W/m2)
	!
	! Note 1 (fcd):
	!
	! An accurate evaluation of the cloudiness function is critical for Rn estimate to yield
	! sensible results. fcd is defined as
	!
	!	fcd = 1.35*(Rg/Rgc) - 0.35
	!
	! where Rg is global radiation, and Rgc the clear-sky radiation computed when solar elevation
	! exceeds a given safety threshold (typically assumed to 0.3 radians computed on mid-averaging
	! period). Defined this way, fcd value is valid only on center-daytime, and undefined elsewhere.
	! But, it may be prolonged by computing an appropriate value on the preceding day's.
	!
	! Alternatively, fcd may be assumed to be fixed to some reference value, derived e.g. by the statistical
	! study of data from a nearby met station equipped with a reliable Rg measurement, and then used to
	! estimate Rg from Rgc:
	!
	!	Rg = Rgc * (fcd + 0.35) / 1.35
	!
	! Although dangerous, the last way may be the only resort when no global radiation measurement
	! is available at met station site.
	!
	! Note 2 (why not cloud cover?):
	!
	! Old PBL_MET estimates made extensive use of cloud cover, a notoriously difficult quantity to get.
	! In this formulation, the information coming from the cloud cover is jointly proxied by fcd, the
	! relatively slowly changing cloudiness function, and Ea, the water vapor pressure (which in case of
	! strong cloud cover will tend to approach saturation pressure, and whose value is intuitively
	! related to cloud cover to some extent).
	!
	function NetRadiation(Rg, albedo, fcd, Ea, Ta) result(Rn)

		implicit none

		! Routine arguments
		real, intent(in)	:: Rg
		real, intent(in)	:: albedo
		real, intent(in)	:: fcd
		real, intent(in)	:: Ea
		real, intent(in)	:: Ta
		real				:: Rn

		! Locals
		real	:: Rns, Rnl		! Short- and long-wave components of net radiation

		! Short-wave component of net radiation is the part which is not reflected
		Rns = Rg*(1.0 - albedo)

		! Long-wave component depends on various things
		Rnl = 5.6722e-8 * fcd * (0.34 - 0.14*SQRT(Ea/10.0)) * Ta**4		! 5.6722e-8 = sigma[MJ / m2 h] * = 2.042e-10 * 1000000 / 3600

		! Finally, the Net Radiation:
		Rn = Rns - Rnl

	end function NetRadiation


	function Cloudiness(rvElAng, rvRg, rvRg3, rSunElevThreshold, rvFcd) result(iRetCode)

		implicit none

		! Routine arguments
		real, dimension(:), intent(in)	:: rvElAng
		real, dimension(:), intent(in)	:: rvRg
		real, dimension(:), intent(in)	:: rvRg3
		real, intent(in)				:: rSunElevThreshold
		real, dimension(:), intent(out)	:: rvFcd
		integer							:: iRetCode

		! Locals
		integer	:: i
		integer	:: iErrCode
		real	:: rFcdOld
		real	:: rFcdFirst
		real	:: rPhi
		real	:: rRatio
		logical:: lIsFirst = .true.

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Iterate over all radiation readings, assumed valid
		rFcdOld   = NaN
		rFcdFirst = NaN
		do i = 1, SIZE(rvRg)
			rPhi = rvElAng(i)
			if(rPhi > rSunElevThreshold) then
				rRatio = MAX(MIN(rvRg(i) / rvRg3(i), 1.0), 0.0)
				rvFcd(i) = 1.35 * rRatio - 0.35
				rFcdOld  = rvFcd(i)
			else
				rvFcd(i) = rFcdOld
			end if
			if(lIsFirst) then
				if(.not.ieee_is_nan(rvFcd(i))) then
					rFcdFirst = rvFcd(i)
					lIsFirst  = .false.
				end if
			end if
		end do
		! Typically, first data items cloudiness remains unassigned
		if(ieee_is_nan(rFcdOld)) then
			iRetCode = 1
			return
		end if

		! Locate first NaNs, and replace them with first over-threshold Cloudiness
		do i = 1, SIZE(rvRg)
			if(ieee_is_nan(rvFcd(i))) then
				rvFcd(i) = rFcdFirst
			end if
		end do

	end function Cloudiness


	! Water vapor saturation pressure, given temperature
	FUNCTION WaterSaturationPressure(Ta) RESULT(es)

		! Routine arguments
		REAL, INTENT(IN)	:: Ta	! Air temperature (K)
		REAL			:: es	! Saturation vapor pressure (hPa)

		! Locals
		! -none-

		! Compute water saturation pressure according to the basic definition
		IF(Ta > 273.15) THEN
			es = EXP(-6763.6/Ta - 4.9283*LOG(Ta) + 54.23)
		ELSE
			es = EXP(-6141.0/Ta + 24.3)
		END IF

	END FUNCTION WaterSaturationPressure


	! Saturation water vapor pressure given air temperature, using
	! ASCE formula, a variant (up to constants decimals) of
	! Clausius-Clapeyron formula. This routine is the recommended
	! replacement of E_SAT.
	!
	!     Input: T = air temperature (∞C)
	!
	!     Output: ESAT = saturation vapor pression (hPa)
	!
	function E_SAT_1(T) result(rEsat)

		! Routine arguments
		real, intent(in)	:: T
		real			:: rEsat

		! Locals
		! -none-

		! Compute the data item required
		rEsat = 6.108*EXP(17.27*T/(T+237.3))

	end function E_SAT_1


	! Precipitable water given water vapor pressure
	!
	!	Input:
	!
	!		Ea		Actual water vapor pressure (hPa)
	!
	!		Pa		Actual pressure at measurement altitude (i.e. not reduced to mean sea level) (hPa)
	!
	!	Output:
	!
	!		W		Precipitable water (mm)
	!
	function PrecipitableWater(Ea, Pa) result(W)

		! Routine arguments
		real, intent(in)	:: Ea, Pa
		real				:: W

		! Locals
		! -none-

		! Compute the data item required
		W = 0.0014*Ea*Pa + 2.1

	end function PrecipitableWater


    ! Compute the derivative of the saturation vapor pressure multiplied
    ! by P/0.622; the input temperature is in ∞K.
	FUNCTION D_E_SAT(T) RESULT(DEsat)

	    ! Routine arguments
	    REAL, INTENT(IN)    :: T
	    REAL                :: DEsat

	    ! Locals
	    REAL, PARAMETER :: E0 =   0.6112
	    REAL, PARAMETER :: a  =  17.67
	    REAL, PARAMETER :: T0 = 273.15
	    REAL, PARAMETER :: Tb =  29.66

	    ! Compute the saturation vapor tension
	    DEsat = E0*a*(1./(T-Tb) + (T-T0)/(T-Tb)**2)*EXP(a*(T-T0)/(T-Tb))
!
	END FUNCTION D_E_SAT


	! Water vapor partial pressure, given wet and dry bulb temperatures and
	! air pressure.
	!
	FUNCTION WaterVaporPressure(Tw, Td, Pa) RESULT(Ew)

		! Routine arguments
		REAL, INTENT(IN)	:: Tw	! Wet bulb temperature (K)
		REAL, INTENT(IN)	:: Td	! Dry bulb temperature (K)
		REAL, INTENT(IN)	:: Pa	! Atmospheric pressure (hPa)
		REAL			:: Ew	! Water vapor partial pressure (hPa)

		! Locals
		REAL	:: TwetCelsius
		REAL	:: ExcessTemp
		REAL	:: FractionalDeltaP

		! Compute the information desired
		TwetCelsius = Tw - 273.15
		ExcessTemp  = Td - Tw		! In Nature dry bulb temperature is greater or equal to wet bulb temperature
		IF(ExcessTemp > 0.) THEN
			FractionalDeltaP = (0.00066/10.) * (1. + 0.00115*TwetCelsius)*ExcessTemp
			Ew               = WaterSaturationPressure(Tw) - FractionalDeltaP * Pa
		ELSE
			Ew               = NaN
		END IF

	END FUNCTION WaterVaporPressure


	! Relative humidity, given wet and dry bulb temperatures and
	! air pressure.
	!
	FUNCTION RelativeHumidity(Tw, Td, Pa) RESULT(RelH)

		! Routine arguments
		REAL, INTENT(IN)	:: Tw	! Wet bulb temperature (K)
		REAL, INTENT(IN)	:: Td	! Dry bulb temperature (K)
		REAL, INTENT(IN)	:: Pa	! Atmospheric pressure (hPa)
		REAL			:: RelH	! Relative humidity (%)

		! Locals
		! --none--

		! Compute the information desired
		RelH = 100. * WaterVaporPressure(Tw, Td, Pa) / WaterSaturationPressure(Td)

	END FUNCTION RelativeHumidity


	! Absolute humidity given dry bulb temperature and water vapor pressure.
	!
	FUNCTION AbsoluteHumidity(Td, Ea) RESULT(RhoW)

		! Routine arguments
		REAL, INTENT(IN)	:: Td	! Dry bulb temperature (K)
		REAL, INTENT(IN)	:: Ea	! Water vapor pressure (hPa)
		REAL			:: RhoW	! Absolute humidity (kg/m3)

		! Locals
		! --none--

		! Compute the information desired
		RhoW = 100.0*Ea/(461.5*Td)

	END FUNCTION AbsoluteHumidity


	! Air density given dry bulb temperature and atmospheric pressure.
	!
	FUNCTION AirDensity_4(Td, Pa) RESULT(Rho)

		! Routine arguments
		REAL, INTENT(IN)	:: Td	! Dry bulb temperature (K)
		REAL, INTENT(IN)	:: Pa	! Atmospheric pressure (hPa)
		REAL			    :: Rho	! Air density (kg/m3)

		! Locals
		! --none--

		! Compute the information desired
		Rho = 100.0*Pa/(287.*Td)

	END FUNCTION AirDensity_4


	! Air density given dry bulb temperature and atmospheric pressure.
	!
	! Double precision version.
	!
	FUNCTION AirDensity_8(Td, Pa) RESULT(Rho)

		! Routine arguments
		REAL(8), INTENT(IN)	:: Td	! Dry bulb temperature (K)
		REAL(8), INTENT(IN)	:: Pa	! Atmospheric pressure (hPa)
		REAL(8) 			:: Rho	! Air density (kg/m3)

		! Locals
		! --none--

		! Compute the information desired
		Rho = 100.0d0*Pa/(287.d0*Td)

	END FUNCTION AirDensity_8


	! Product of air density and the constant-pressure atmospheric thermal capacity,
	! given dry bulb temperature and atmospheric pressure.
	!
	FUNCTION RhoCp_4(Td, Pa) RESULT(rRhoCp)

		! Routine arguments
		REAL, INTENT(IN)		    :: Td		! Dry bulb temperature (K)
		REAL, INTENT(IN), OPTIONAL	:: Pa		! Air pressure (hPa)
		REAL				        :: rRhoCp	! Product of air density and
								                ! constant-pressure thermal
								                ! capacity

		! Locals
		REAL	:: Rho
		REAL	:: Cp

		! Compute the information desired
		IF(PRESENT(Pa)) THEN
			! Pressure is available: use complete formula
			Rho = AirDensity(Td, Pa)
			Cp  = 1005.0 + (Td - 250.0)**2/3364.0	! From Garratt, 1992
			rRhoCp = Rho * Cp
		ELSE
			! Pressure not available on entry: use the simplified relation
			rRhoCp = 1305. * 273.15/Td
		END IF

	END FUNCTION RhoCp_4


	! Product of air density and the constant-pressure atmospheric thermal capacity,
	! given dry bulb temperature and atmospheric pressure.
	!
	! Double precision version.
	!
	FUNCTION RhoCp_8(Td, Pa) RESULT(rRhoCp)

		! Routine arguments
		REAL(8), INTENT(IN)		        :: Td		! Dry bulb temperature (K)
		REAL(8), INTENT(IN), OPTIONAL	:: Pa		! Air pressure (hPa)
		REAL(8) 				        :: rRhoCp	! Product of air density and
								                    ! constant-pressure thermal
								                    ! capacity

		! Locals
		REAL(8)	:: Rho
		REAL(8)	:: Cp

		! Compute the information desired
		IF(PRESENT(Pa)) THEN
			! Pressure is available: use complete formula
			Rho = AirDensity_8(Td, Pa)
			Cp  = 1005.0d0 + (Td - 250.0d0)**2/3364.0d0	! From Garratt, 1992
			rRhoCp = Rho * Cp
		ELSE
			! Pressure not available on entry: use the simplified relation
			rRhoCp = 1305.d0 * 273.15d0/Td
		END IF

	END FUNCTION RhoCp_8


	! Latent vaporization heat given temperature,
	! computed according the ASCE Report.
	function LatentVaporizationHeat(rTemp, iCalculationType) result(rLambda)

		! Routine arguments
		real, intent(in)	:: rTemp			! (°C)
		integer, intent(in)	:: iCalculationType	! ASCE_STANDARDEQ, ASCE_MEANTEMPERATURE
		real				:: rLambda			! (W/m2)

		! Locals
		! -none-

		! Compute the information desired
		select case(iCalculationType)
		case(ASCE_STANDARDEQ)
			rLambda = 2.45 * 1.e6 / 3600.0
		case(ASCE_MEANTEMPERATURE)
			rLambda = (2.501 - 2.361e-3 * rTemp) * 1.e6 / 3600.0
		case default
			rLambda = NaN
		end select

	end function LatentVaporizationHeat


	! Estimate wet bulb temperature from dry bulb temperature, relative
	! humidity and pressure.
	!
	! The estimation is computed by solving the equation
	!
	!	Delta(Tw, Td, Ur, Pa) = 0
	!
	! for "Tw", where "Delta" is found later in the auxiliary functions
	! part of this module. As "Delta" is not everywhere differentiable with
	! respect to "Tw", for prudence a derivative-independent solver is used.
	! Actually, a two-stage approach has been followed: in the first stage
	! an initial rough bracketing of the solution is progressively made
	! smaller by bisection method. In second stage, the final solution is
	! found by secant method.
	!
	! Usage note:	Rough and fine tolerances, "RoughTol" and "FineTol", are
	! ===========	typically set to 0.1 and 0.001 respectively. In my feeling
	!		there is no real need to change them, so I made both parameters
	! optional with appropriate defaults. But on occasions you may want to experiment
	! with different values. In this case, you should ensure that
	!
	!	RoughTol << FineTol
	!
	! I recommend the fine tolerance to be some orders of magnitude smaller than
	! the rough tolerance; the smaller the rough tolerance, the higher iteration count
	! will be in bisection phase (which is more robust than secant method, but less
	! "efficient", in the sense convergence is slower).
	!
	FUNCTION WetBulbTemperature(Td, Ur, Pa, RoughTol, FineTol, MaxIter, Method) RESULT(Tw)

		! Routine arguments
		REAL, INTENT(IN)		:: Td		! Dry bulb (that is "ordinary") temperature (K)
		REAL, INTENT(IN)		:: Ur		! Relative humidity (%)
		REAL, INTENT(IN)		:: Pa		! Air pressure (hPa)
		REAL, INTENT(IN), OPTIONAL	:: RoughTol	! Maximum bracketing step error admitted on wet bulb temperature (K, default 0.1)
		REAL, INTENT(IN), OPTIONAL	:: FineTol	! Maximum refinement step error admitted on wet bulb temperature (K, default 0.001)
		INTEGER, INTENT(IN), OPTIONAL	:: MaxIter	! Maximum number of iterations (default: 100)
		INTEGER, INTENT(IN), OPTIONAL	:: Method	! Method used for performing calculations (1:Standard (default), 2:Simplified - see R. Stull, "Wet bulb temperature from relative humidity and air temperature", Bulletin of the AMS, Nov 2011)
		REAL				:: Tw		! Wet bulb temperature (K)

		! Locals
		REAL	:: rRoughTol
		REAL	:: rFineTol
		INTEGER	:: iMaxIter
		INTEGER	:: iMethod
		REAL	:: a, b			! Minimum and maximum of bracketing interval
		REAL	:: da, db		! Delta values corresponding to a and b respectively

		! Set default input parameters
		IF(PRESENT(RoughTol)) THEN
			rRoughTol = RoughTol
		ELSE
			rRoughTol = 0.1
		END IF
		IF(PRESENT(FineTol)) THEN
			rFineTol = FineTol
		ELSE
			rFineTol = 0.001
		END IF
		IF(PRESENT(MaxIter)) THEN
			iMaxIter = MaxIter
		ELSE
			iMaxIter = 100
		END IF
		IF(PRESENT(Method)) THEN
			iMethod = Method
		ELSE
			iMethod = 1
		END IF

		! Dispatch execution based on method
		SELECT CASE(iMethod)

		CASE(1)

			! Bracket solution using bisection method first
			CALL Bisect(0., Td, Ur, Pa, rRoughTol, a, b, da, db)
			Tw = Secant(a, b, da, db, Td, Ur, Pa, rFineTol, iMaxIter)

		CASE(2)

			! Stull simplified method
			Tw = (Td-273.15) * ATAN(0.151977*SQRT(Ur + 8.313659)) + ATAN(Td-273.15 + Ur) - ATAN(Ur - 1.676331) + &
				 0.00391838*Ur**1.5 * ATAN(0.023101 * Ur) - 4.686035 + 273.15

		CASE DEFAULT

			! Bracket solution using bisection method first
			CALL Bisect(0., Td, Ur, Pa, rRoughTol, a, b, da, db)
			Tw = Secant(a, b, da, db, Td, Ur, Pa, rFineTol, iMaxIter)

		END SELECT

	END FUNCTION WetBulbTemperature
	!
	! Motivations and whys - I've chosen a two-staged approach in which first is
	! ====================   bisection because this algorithm is sturdy, although
	!                        inefficient. As "Delta" is a monotonically increasing
	! function, but with one essential discontinuity at 0 °C (just where we need it
	! the most) I preferred this approach to bracket the solution to a tiny interval
	! so that the chance of finding adverse effects due to the discontinuity are
	! minimized. Once the search interval is well reduced
	! the final solution is found by secant method, more efficient but
	! somewhat less robust than bisection.
	!
	! That "Delta" is really increasing with "Tw" you can check on yourself by
	! direct inspection or testing (I've used both). Anyway, monotonicity of
	! "Delta" is essential for this routine to work as intended.
	!
	! Note about Stull method. As you can see I've implemented Stull's new simplified
	! method (non-default parameter Method==2). Then I've tested it, and found it to
	! depart quite significantly from the true value; on occasions I've noticed the
	! predicted wet bulb temperature to exceed dry bulb, which cannot be for physical reasons.
	! Investigations should be performed to check where is Stull method best suited. I guess
	! the range will depend on pressure being close to reference value.


	! Estimate atmospheric pressure given height
	function AirPressure1(rZ) result(rPk)

		implicit none

		! Routine arguments
		real, intent(in)	:: rZ				! Altitude at which pressure is desired (m above msl)
		real				:: rPk				! Estimated pressure (hPa)

		! Locals
		real		:: rTK0		! Reference temperature (K)

		! Constants
		real, parameter	:: P0 = 1013.		! Pressure at reference altitude (hPa)
		real, parameter	:: g  = 9.807		! Gravitation acceleration (m/s2)
		real, parameter	:: z0 = 0.			! Reference altitude for expressing pressure (m above msl)
		real, parameter	:: R  = 287.0		! Specific gas constant (J/kg/K)
		real, parameter	:: Alpha1 = 0.0065	! Constant lapse rate of moist air (K/m)

		! Reference temperature
		rTK0 = 293.15

		! Compute pressure
		rPk = P0*((rTK0 - Alpha1*(rZ - z0))/rTK0)**(g/(Alpha1*R))

	end function AirPressure1


	! Estimate atmospheric pressure given height and temperature
	function AirPressure2(rZ, rTemp, rZr, iCalculationType) result(rPk)

		implicit none

		! Routine arguments
		real, intent(in)	:: rZ				! Altitude at which pressure is desired (m above msl)
		real, intent(in)	:: rTemp			! Air temperature (°C)
		real, intent(in)	:: rZr				! Height at which temperature measurements are taken (m)
		integer, intent(in)	:: iCalculationType	! ASCE_STANDARDATMOSPHERE, ASCE_STANDARDEQ, ASCE_MEANTEMPERATURE
		real				:: rPk				! Estimated pressure (hPa)

		! Locals
		real		:: rTK0		! Reference temperature (K)

		! Constants
		real, parameter	:: P0 = 1013.		! Pressure at reference altitude (hPa)
		real, parameter	:: g  = 9.807		! Gravitation acceleration (m/s2)
		real, parameter	:: z0 = 0.			! Reference altitude for expressing pressure (m above msl)
		real, parameter	:: R  = 287.0		! Specific gas constant (J/kg/K)
		real, parameter	:: Alpha1 = 0.0065	! Constant lapse rate of moist air (K/m)

		! Reference temperature
		select case(iCalculationType)
		case(ASCE_STANDARDATMOSPHERE)
			rTK0 = 288.0
		case(ASCE_STANDARDEQ)
			rTK0 = 293.0
		case(ASCE_MEANTEMPERATURE)
			rTK0 = rTemp + 273.15
		case default
			rPk = NaN
			return
		end select

		! Compute pressure
		rPk = P0*((rTK0 - Alpha1*(rZ - z0))/rTK0)**(g/(Alpha1*R))

	end function AirPressure2


	function VirtualTemperature(Temp, ea, P) result(Tv)

		implicit none

		! Routine arguments
		real, intent(in)	:: Temp		! (°C)
		real, intent(in)	:: ea		! (hPa)
		real, intent(in)	:: P		! (hPa)
		real				:: Tv		! (°C)

		! Locals
		! -none-

		! Compute the information desired
		Tv = (Temp + 273.15)/(1.0 - 0.378*ea/P) - 273.15

	end function VirtualTemperature


	! Estimate dew point temperature using Magnus formula enhanced using Arden Buck equation
	FUNCTION DewPointTemperature(Td, Ur) RESULT(Dp)

		! Routine arguments
		REAL, INTENT(IN)				:: Td		! Dry bulb (that is "ordinary") temperature (K)
		REAL, INTENT(IN)				:: Ur		! Relative humidity (%)
		REAL						    :: Dp       ! Dew point (K)

		! Locals
		REAL, PARAMETER	:: a =   6.112
		REAL, PARAMETER	:: b =  17.62
		REAL, PARAMETER	:: c = 243.12
		REAL, PARAMETER	:: d = 234.5
		REAL		:: T, G

		! Convert temperature to °C (all relations we use assume Celsius degrees)
		! and then obtain dew point temperature
		T  = Td - 273.15
		G  = LOG(Ur/100.0*EXP((b-T/d)*(T/(c+T))))
		Dp = c*G/(b-G) + 273.15

	END FUNCTION DewPointTemperature


	! Estimate sonic temperature given dry bulb ("normal") temperature, relative
	! humidity and atmospheric pressure.
	!
	! Routine "SonicTemperature" must compute wet bulb temperature estimate prior
	! to compute the desired sonic temperature value. The most apparent consequence
	! is tolerances and method are necessary too. The second effect is the resulting
	! estimate, based itself on estimates, may be quite poor.
	!
	! See documentation of "WetBulbTemperature" for clarifications.
	!
	FUNCTION SonicTemperature(Td, Ur, Pa, RoughTol, FineTol, MaxIter, Method) RESULT(Ts)

		! Routine arguments
		REAL, INTENT(IN)		:: Td		! Dry bulb (that is "ordinary") temperature (K)
		REAL, INTENT(IN)		:: Ur		! Relative humidity (%)
		REAL, INTENT(IN)		:: Pa		! Air pressure (hPa)
		REAL, INTENT(IN), OPTIONAL	:: RoughTol	! Maximum bracketing step error admitted on wet bulb temperature (K, default 0.1)
		REAL, INTENT(IN), OPTIONAL	:: FineTol	! Maximum refinement step error admitted on wet bulb temperature (K, default 0.001)
		INTEGER, INTENT(IN), OPTIONAL	:: MaxIter	! Maximum number of iterations (default: 100)
		INTEGER, INTENT(IN), OPTIONAL	:: Method	! Method used for performing calculations (1:Standard (default), 2:Simplified - see R. Stull, "Wet bulb temperature from relative humidity and air temperature", Bulletin of the AMS, Nov 2011)
		REAL				:: Ts		! Sonic temperature (K)

		! Locals
		REAL	:: rRoughTol
		REAL	:: rFineTol
		INTEGER	:: iMaxIter
		INTEGER	:: iMethod
		REAL	:: Tw

		! Set default input parameters
		IF(PRESENT(RoughTol)) THEN
			rRoughTol = RoughTol
		ELSE
			rRoughTol = 0.1
		END IF
		IF(PRESENT(FineTol)) THEN
			rFineTol = FineTol
		ELSE
			rFineTol = 0.001
		END IF
		IF(PRESENT(MaxIter)) THEN
			iMaxIter = MaxIter
		ELSE
			iMaxIter = 100
		END IF
		IF(PRESENT(Method)) THEN
			iMethod = Method
		ELSE
			iMethod = 1
		END IF

		! Compute the ultrasonic anemometer temperature estimate by
		! applying the direct definition
		Tw = WetBulbTemperature(Td, Ur, Pa, RoughTol, FineTol, MaxIter, Method)
		Ts = Td*(1.+0.51*0.622*WaterVaporPressure(Tw, Td, Pa)/Pa)

	END FUNCTION SonicTemperature


	! Estimate solar global radiation using the MPDA method
	function GlobalRadiation_MPDA(C, sinPsi) result(Rg)

		! Routine arguments
		real, intent(in)	:: C		! Cloud cover fraction (0 to 1)
		real, intent(in)	:: sinPsi	! Sine of solar elevation angle (° above horizon; negative below)
		real				:: Rg		! Estimate of the global solar radiation (W/m2)1-0.75

		! Locals
		real	:: rSinMin
		real	:: rCloud

		! Constants
		real, parameter	:: a1 = 990.
		real, parameter	:: a2 = -30.
		real, parameter	:: b1 =  -0.75
		real, parameter	:: b2 =   3.4

		! Check input parameter make sense
		if((.invalid.C) .or. (.invalid.sinPsi)) then
			Rg = NaN
			return
		end if
		if(C < 0. .or. sinPsi < -1. .or. sinPsi > 1.) then
			Rg = NaN
			return
		end if

		! Constrain cloud cover to senseful interval
		rCloud = max(min(C, 1.), 0.)

		! Estimate the minimum sine of solar elevation
		rSinMin = - a2 / a1
		if(sinPsi >= rSinMin) then
			Rg = (a1*sinPsi*exp(-0.057/sinPsi))*(1.+b1*rCloud**b2)
		else
			Rg = 0.
		end if

	end function GlobalRadiation_MPDA


	! Estimate the cloud cover using MPDA method
	function CloudCover_MPDA(Rg, sinPsi) result(C)

		! Routine arguments
		real, intent(in)	:: Rg		! Global radiation (W/m2)
		real, intent(in)	:: sinPsi	! Sine of solar elevaton angle
		real				:: C		! Cloud cover fraction

		! Locals
		real	:: rSinMin
		real	:: maxRg

		! Constants
		real, parameter	:: a1 = 990.
		real, parameter	:: a2 = -30.
		real, parameter	:: b1 =  -0.75
		real, parameter	:: b2 =   3.4

		rSinMin = -a2/a1
		if(sinPsi >= rSinMin) then
			maxRg =  a1*sinPsi * exp(-0.057/sinPsi)
			if(Rg >= maxRg) then
				C = 0.
			else
				C = (1./b1*(Rg/maxRg-1.))**(1./b2)
			end if
		else
			C = 0.5
		end if

	end function CloudCover_MPDA


	! Estimate the net radiation by MPDA method. The relation used,
	! based on a grey body approximation, tends to be accurate when
	! the global radiation is greater than zero, then on daytime.
	! Over night-time (actually, when the value returned by this
	! function is negative), the function NighttimeNetRadiation
	! should be called instead
	function NetRadiation_MPDA(land, albedo, Td, Rg, C, z0, zr, vel) result(Rn)

		! Routine arguments
		integer, intent(in)	:: land			! Simplified land use code:
											!   1: Desert
											!   2: Dry rural
											!   3: Dense urban fabric
											!   4: Sparse urban fabric, sub-urban
											!   5: Forests, prairies, irrigated coltures
											!   6: Water bodies
		real, intent(in)	:: albedo		! Albedo coefficient
		real, intent(in)	:: Td			! Dry bulb (ordinary) temperature (°C)
		real, intent(in)	:: Rg			! Global radiation (W/m2)
		real, intent(in)	:: C			! Cloud cover fraction (0 to 1)
		real, intent(in)	:: z0			! Aerodynamic roughness length (m)
		real, intent(in)	:: zr			! Anemometer height above ground (m)
		real, intent(in)	:: vel			! Wind speed (m/s)
		real				:: Rn			! Estimated net radiation (W/m2)

		! Locals
		real	:: Ta
		real	:: a
		real	:: s
		real	:: tt
		real	:: c3
		real	:: u2
		integer	:: k

		! Constant parameters
		real, dimension(6), parameter	:: alpha = [0.1, 0.3, 0.5, 0.8, 1.0, 1.4]
		real, dimension(9), parameter	:: a0    = [-96.1,-101.5,-76.1,-80.1,-53.5,-45.3,-35.5,-23.0,-9.9]
		real, dimension(4), parameter	:: a1    = [-16.4,-12.6,-13.0,-9.8]
		real, dimension(4), parameter	:: a2    = [1.35,0.99,1.16,0.9]
		real, dimension(4), parameter	:: a3    = [100.e-15,104.e-15,66.e-15,72.e-15]
		real, parameter					:: c1    = 5.31e-13
		real, parameter					:: c2    = 60.
		real, parameter					:: sigma = 5.67e-08
		real, parameter					:: pi    = 3.14159265

		! Check parameters
		if(C < 0. .or. C > 1.) then
			Rn = NaN
			return
		end if

		! Compute a preliminary estimate of net radiation
		Ta = Td + 273.15
		a  = alpha(land)
		s  = 1.05*exp((6.42-Td)/17.78)
		c3 = 0.38*((1.-a)+1.)/(1.+s)
		Rn = ((1.-albedo)*Rg+c1*Ta**6-sigma*Ta**4+c2*C)/(1.+c3)

		! If the preliminary estimate is negative apply the "nocturnal" formula
		! to get a more refined estimate
		if(Rn < 0.) then
			k = nint(C*8.) + 1		! 'k' belongs to range 1..9
			if(k > 4) then
				Rn = a0(k)
			else
				u2 = log(2./z0)/log(zr/z0) * vel
				Rn = a0(k) + a1(k)*u2 + a2(k)*u2*u2 + a3(k)*Ta**6
			end if
		end if

	end function NetRadiation_MPDA


	! Indicative evaluation of Brunt-Vaisala frequency. Notice this function yields a valid value
	! even under unstable situations, when in principle the Brunt-Vaisala frequency is not
	! defined: this is intentional, and may be overcome by programmatically invalidate the values obtained under
	! neutral and unstable conditions.
	function BruntVaisala(Td, z) result(N)

		! Routine arguments
		real, intent(in)	:: Td	! Virtual temperature (°C)
		real, intent(in)	:: z	! Height above ground level (m)
		real				:: N	! Brunt-Vaisala frequency (Hz)

		! Locals
		real	:: Tpot	! Potential temperature (K)

		! Compute the information desired
		if(z < 0. .OR. Td < -100.) then
			N = NaN
			return
		endif
		Tpot = Td + 273.15 + 0.0098 * z
		N    = sqrt(abs(9.807/Tpot * 0.0098))

	end function BruntVaisala



	! ***************************************
	! * Auxiliary functions (not accessible *
	! * through public interface)           *
	! ***************************************


	! Auxiliary function used by "TWET" for estimating wet bulb temperature. Given dry
	! bulb temperature, relative humidity and air pressure the wet bulb temperature is
	! the value of "Tw" at which the auxiliary function is 0.
	!
	! A simple analysis may show the auxiliary function to be monotonically increasing
	! with Tw in the interval 0 <= Tw <= Td.
	!
	! It is useful to understand where "Delta" comes from. The starting point is the
	! equation giving water vapor partial pressure,
	!
	!	E = ESAT(Tw) - 0.00066*(1.+0.00115*(Tw-273.15))*(Pa/10.)*(Td-Tw)				       (1)
	!
	! where "Tw" and "Td" are wet and dry bulb temperatures, "Pa" is air pressure,
	! and ESAT(T) the water vapor saturation pressure at temperature T.
	!
	! Now, let's consider water vapor partial pressure: the following definition
	! connects it to relative humidity, "Ur", and ESAT(Td).
	!
	!	Ur = 100.*E/ESAT(Td)
	!
	! This relation is the same as
	!
	!	E = (Ur/100.)*ESAT(Td)
	!
	! which, upon replacing in formula (1) yields
	!
	!	(Ur/100.)*ESAT(Td) = ESAT(Tw) - 0.00066*(1.+0.00115*(Tw-273.15))*(Pa/10.)*(Td-Tw)
	!
	! or
	!
	!	ESAT(Tw) - 0.00066*(1.+0.00115*(Tw-273.15))*(Pa/10.)*(Td-Tw) - (Ur/100.)*ESAT(Td) = 0  (2)
	!
	! This latter is an equation in "Tw", whose solution is the desired wet bulb
	! temperature. Monotonicity with respect to "Tw" then guarantees the solution
	! uniqueness (not its existence, however: ESAT(T) has a discontinuity at 0 °C
	! at which existence cannot be ensured a priori).
	!
	! The left member of equation (2) can be considered a function in "Tw", whose
	! value starts negative, to reach zero at wet bulb temperature, and finally
	! becomes positive. By solving it numerically, we get the desired wet bulb temperature.
	!
	FUNCTION Delta(Tw, Td, Ur, Pa) RESULT(d)

		! Routine arguments
		REAL, INTENT(IN)	:: Tw	! Tentative wet bulb temperature (K)
		REAL, INTENT(IN)	:: Td	! Known dry bulb temperature (K)
		REAL, INTENT(IN)	:: Ur	! Known relative humidity (%)
		REAL, INTENT(IN)	:: Pa	! Known atmospheric pressure (hPa)
		REAL			:: d	! The corresponding value of auxiliary function.

		! Locals
		! -none-

		! Compute the information desired
		d = WaterVaporPressure(Tw, Td, Pa) - (Ur/100.)*WaterSaturationPressure(Td)

	END FUNCTION Delta


	! Dedicated implementation of bisection method. It differs from the
	! standard algorithm by:
	!
	!	1)	It solves *only* equation "Delta() == 0" (see above)
	!	2)	No limit on iteration count
	!
	! The reason of the second point above is that the number of iterations
	! required, O(log2(273,15/Tol)), is always small if accuracy is in the
	! expected range 0.1-0.01.
	!
	! Bisection is used to restrict the initial solution bracketing interval
	! [0,Td] to [TwMin,TwMax] where
	!
	!	TwMax - TwMin <= Tol
	!
	! so that further use of secant method is guaranteed to easily converge.
	! Subroutine interface of Bisect is designed to provide all initialization
	! data (namely, including "da" and "db") to Secant saving a couple of function
	! evaluation: it *is* redundant, but this redundancy is desired.
	!
	SUBROUTINE Bisect(TdMin, TdMax, Ur, Pa, Tol, a, b, da, db)

		! Routine arguments
		REAL, INTENT(IN)	:: TdMin	! Initial lower bound of temperature (K)
		REAL, INTENT(IN)	:: TdMax	! Dry bulb temperature (K)
		REAL, INTENT(IN)	:: Ur		! Relative humidity (%)
		REAL, INTENT(IN)	:: Pa		! Atmospheric pressure (hPa)
		REAL, INTENT(IN)	:: Tol		! Tolerance (K)
		REAL, INTENT(OUT)	:: a		! Lower bound on temperature (K)
		REAL, INTENT(OUT)	:: b		! Upper bound on temperature (K)
		REAL, INTENT(OUT)	:: da		! Value of "Delta" at "a"
		REAL, INTENT(OUT)	:: db		! Value of "Delta" at "b"

		! Locals
		REAL	:: p
		REAL	:: dp

		! Initialize
		a  = TdMin
		da = Delta(a, TdMax, Ur, Pa)
		b  = TdMax
		db = Delta(b, TdMax, Ur, Pa)

		! Main loop: bisect interval until rough tolerance is met, or an error is found
		DO
			p  = a + (b-a)/2
			dp = Delta(p, TdMax, Ur, Pa)
			IF(da*dp > 0.) THEN
				a  = p
				da = dp
			ELSE
				b  = p
				db = dp
			END IF
			IF((b-a)/2. < Tol) EXIT
		END DO

	END SUBROUTINE Bisect


	! Dedicated routine for refining the estimate of wet bulb temperature
	! obtained from Bisect.
	FUNCTION Secant(a0, b0, da0, db0, Td, Ur, Pa, Tol, MaxIter) RESULT(Tw)

		! Routine arguments
		REAL, INTENT(IN)	:: a0		! Initial lower bound of wet bulb temperature (K)
		REAL, INTENT(IN)	:: b0		! Initial upper bound of wet bulb temperature (K)
		REAL, INTENT(IN)	:: da0		! Value of "Delta" at "a0"
		REAL, INTENT(IN)	:: db0		! Value of "Delta" at "b0"
		REAL, INTENT(IN)	:: Td		! Dry bulb temperature (K)
		REAL, INTENT(IN)	:: Ur		! Relative humidity (%)
		REAL, INTENT(IN)	:: Pa		! Atmospheric pressure (hPa)
		REAL, INTENT(IN)	:: Tol		! Tolerance (K)
		INTEGER, INTENT(IN)	:: MaxIter	! Maximum number of iterations
		REAL			:: Tw		! Wet bulb temperature (K)

		! Locals
		REAL	:: p
		REAL	:: dp
		REAL	:: a
		REAL	:: da
		REAL	:: b
		REAL	:: db
		INTEGER	:: Iteration

		! Initialization
		a  = a0
		da = da0
		b  = b0
		db = db0
		Iteration = 1

		! Main loop
		DO
			p = b - db*(b-a)/(db-da)
			IF(ABS(p - b) < Tol) EXIT
			a  = b
			da = db
			b  = p
			db = Delta(p, Td, Ur, Pa)
			Iteration = Iteration + 1
			IF(Iteration >= MaxIter) EXIT
		END DO

		! Transmit result and leave
		Tw = p

	END FUNCTION Secant

end module pbl_thermo


! pbl_wind - Fortran module, containing routines related to wind
!            in the Planetary Boundary Layer.
!
! This module is part of the pbl_met library.
!
! Copyright 2018 by Servizi Territorio srl
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_wind

	use ieee_arithmetic
	use pbl_base
	use pbl_time
	use pbl_thermo

	implicit none

	private

	! Public interface
	! 0. Useful constants and symbols
	public	:: WCONV_SAME
	public	:: WCONV_PROVENANCE_TO_FLOW
	public	:: WCONV_FLOW_TO_PROVENANCE
	public	:: WDCLASS_ZERO_CENTERED
	public	:: WDCLASS_ZERO_BASED
	public	:: SONIC_USONIC3
	public	:: SONIC_USA1
	public	:: SPK_REMOVE
	public	:: SPK_CLIP
	! 1. Conventions
	public	:: PolarToCartesian2
	public	:: PolarToCartesian3
	public	:: CartesianToPolar2
	public	:: CartesianToPolar3
	! 2. Classification
	public	:: ClassVel
	public	:: ClassDir
	! 3. Descriptive statistics
	public	:: VectorDirVel
	public	:: ScalarVel
	public	:: UnitDir
	public	:: WindRose
	public	:: CompareWindRoses
	public	:: VelDirMean
	public	:: VelMean
	public	:: DirMean
	! 4. Data types
	public	:: SonicData
	public	:: TrendData
	public	:: SpikeCounts
	public	:: EddyCovData

	! Public constants
	integer, parameter	:: WCONV_SAME               = 0
	integer, parameter	:: WCONV_PROVENANCE_TO_FLOW = 1
	integer, parameter	:: WCONV_FLOW_TO_PROVENANCE = 2
	integer, parameter	:: WDCLASS_ZERO_CENTERED    = 0
	integer, parameter	:: WDCLASS_ZERO_BASED       = 1
	integer, parameter	:: SONIC_USONIC3			= 0
	integer, parameter	:: SONIC_USA1				= 1
	integer, parameter	:: SPK_REMOVE				= 0
	integer, parameter	:: SPK_CLIP					= 1

	! Internal constants
	real, parameter		:: Pi = 3.1415927
	real, parameter		:: ToRad = Pi/180.
	real, parameter		:: ToDeg = 180./Pi
	real, parameter		:: MOL_AIR   = 28.96	! Molar mass of dry air (g/mol)
	real, parameter		:: MOL_H2O   = 18.0153	! Molar mass of water (g/mol)
	real, parameter		:: MOL_CO2   = 44.0100	! Molar mass of carbon dioxide (g/mol)

	! Polymorphic interfaces

	interface ClassVel
		module procedure ClassVelScalar
		module procedure ClassVelVector
	end interface ClassVel

	interface ClassDir
		module procedure ClassDirScalar
		module procedure ClassDirVector
	end interface ClassDir

	! Data types

	! Type for ultrasonic anemometer raw data.
	type SonicData
		! State variables
		logical, private							:: isValid
		! Input data
		real(8), dimension(:), allocatable, private	:: rvTimeStamp
		real, dimension(:), allocatable, private	:: rvU
		real, dimension(:), allocatable, private	:: rvV
		real, dimension(:), allocatable, private	:: rvW
		real, dimension(:), allocatable, private	:: rvT
		real, dimension(:), allocatable, private	:: rvQ
		real, dimension(:), allocatable, private	:: rvC
		! Derived quantities
		real(8), dimension(:), allocatable, private	:: rvVel
		real(8), dimension(:), allocatable, private	:: rvVel3D
		real, dimension(:), allocatable, private	:: rvUnitU
		real, dimension(:), allocatable, private	:: rvUnitV
	contains
		procedure	:: buildFromVectors	=> sd_BuildFromVectors
		procedure	:: getVectors       => sd_GetVectors
		procedure	:: getSpeed         => sd_GetSpeed
		procedure	:: readSonicLib		=> sd_ReadSonicLib
		procedure	:: readWindRecorder	=> sd_ReadWindRecorder
		procedure	:: readMeteoFlux	=> sd_ReadMeteoFluxCoreUncompressed
		procedure	:: writeSonicLib	=> sd_WriteSonicLib
		procedure	:: size				=> sd_Size
		procedure	:: valid			=> sd_Valid
		procedure	:: isWater			=> sd_IsWater
		procedure	:: isCarbonDioxide	=> sd_IsCarbonDioxide
		procedure	:: removeTrend		=> sd_RemoveTrend
		procedure	:: treatSpikes		=> sd_TreatSpikes
		procedure	:: averages			=> sd_Averages
	end type SonicData

	! Type for storing trend (removal) parameters
	type TrendData
		integer, dimension(:), allocatable		:: ivNumData
		real(8), dimension(:), allocatable		:: rvAlphaU
		real(8), dimension(:), allocatable		:: rvAlphaV
		real(8), dimension(:), allocatable		:: rvAlphaW
		real(8), dimension(:), allocatable		:: rvAlphaT
		real(8), dimension(:), allocatable		:: rvAlphaQ
		real(8), dimension(:), allocatable		:: rvAlphaC
		real(8), dimension(:), allocatable		:: rvBetaU
		real(8), dimension(:), allocatable		:: rvBetaV
		real(8), dimension(:), allocatable		:: rvBetaW
		real(8), dimension(:), allocatable		:: rvBetaT
		real(8), dimension(:), allocatable		:: rvBetaQ
		real(8), dimension(:), allocatable		:: rvBetaC
		real(8), dimension(:), allocatable		:: rvS2epsU
		real(8), dimension(:), allocatable		:: rvS2epsV
		real(8), dimension(:), allocatable		:: rvS2epsW
		real(8), dimension(:), allocatable		:: rvS2epsT
		real(8), dimension(:), allocatable		:: rvS2epsQ
		real(8), dimension(:), allocatable		:: rvS2epsC
		real(8), dimension(:), allocatable		:: rvS2alphaU
		real(8), dimension(:), allocatable		:: rvS2alphaV
		real(8), dimension(:), allocatable		:: rvS2alphaW
		real(8), dimension(:), allocatable		:: rvS2alphaT
		real(8), dimension(:), allocatable		:: rvS2alphaQ
		real(8), dimension(:), allocatable		:: rvS2alphaC
		real(8), dimension(:), allocatable		:: rvS2betaU
		real(8), dimension(:), allocatable		:: rvS2betaV
		real(8), dimension(:), allocatable		:: rvS2betaW
		real(8), dimension(:), allocatable		:: rvS2betaT
		real(8), dimension(:), allocatable		:: rvS2betaQ
		real(8), dimension(:), allocatable		:: rvS2betaC
	contains
		procedure	:: clean			=> td_Clean
		procedure	:: reserve			=> td_Allocate
	end type TrendData

	! Type for storing spike (removal) parameters
	type SpikeCounts
		integer, dimension(:), allocatable		:: ivNumSpikesU
		integer, dimension(:), allocatable		:: ivNumSpikesV
		integer, dimension(:), allocatable		:: ivNumSpikesW
		integer, dimension(:), allocatable		:: ivNumSpikesT
		integer, dimension(:), allocatable		:: ivNumSpikesQ
		integer, dimension(:), allocatable		:: ivNumSpikesC
	contains
		procedure	:: clean			=> sc_Clean
		procedure	:: reserve			=> sc_Allocate
	end type SpikeCounts

	! Results of basic eddy covariance processing
	type EddyCovData
		! Status section
		logical, private									:: isPrimed			! .true. when "averages" are available
		logical, private									:: isFilled			! .true. when eddy covariance data are available
		integer, private									:: averagingTime	! Averaging time, in seconds
		! Common-to-all data
		real(8), dimension(:), allocatable, private			:: rvTimeStamp		! Time stamp averages
		integer, dimension(:), allocatable, private			:: ivNumData		! Number of (valid) data having contributed to the "averages"
		! Input section (data entering here through SonicData % averages(...) member function
		real(8), dimension(:,:), allocatable, private		:: rmVel			! Time series of mean velocities (m/s)
		real(8), dimension(:), allocatable, private			:: rvT				! Time series of mean temperatures (°C)
		real(8), dimension(:), allocatable, private			:: rvQ				! Time series of mean water concentration (mmol/mol)
		real(8), dimension(:), allocatable, private			:: rvC				! Time series of mean carbon dioxide concentrations (mmol/mol)
		real(8), dimension(:,:,:), allocatable, private		:: raCovVel			! Time series of momentum covariances (m2/s2)
		real(8), dimension(:,:), allocatable, private		:: rmCovT			! Time series of covariances between velocities and temperature (m°C/s)
		real(8), dimension(:), allocatable, private			:: rvVarT			! Time series of temperature variances (°C2)
		real(8), dimension(:,:), allocatable, private		:: rmCovQ			! Time series of covariances between velocities and water (m mmol/mol s)
		real(8), dimension(:), allocatable, private			:: rvVarQ			! Time series of water variances (mmol2/mol2)
		real(8), dimension(:,:), allocatable, private		:: rmCovC			! Time series of covariances between velocities and carbon dioxide (m mmol/mol s)
		real(8), dimension(:), allocatable, private			:: rvVarC			! Time series of carbon dioxide variances (mmol2/mol2)
		! Output section (data entering here through EddyCovData % process(...) member function
		! 1) Basic, rotated
		real(8), dimension(:), allocatable, private			:: rvTheta			! Time series of first rotation angles (°)
		real(8), dimension(:), allocatable, private			:: rvPhi			! Time series of second rotation angles (°)
		real(8), dimension(:), allocatable, private			:: rvPsi			! Time series of third rotation angles (°) (always 0 if two rotations selected in eddy covariance)
		real(8), dimension(:,:), allocatable, private		:: rmRotVel			! Time series of rotated mean velocities (m/s)
		real(8), dimension(:,:,:), allocatable, private		:: raRotCovVel		! Time series of rotated momentum covariances (m2/s2)
		real(8), dimension(:,:), allocatable, private		:: rmRotCovT		! Time series of rotated covariances between velocities and temperature (m°C/s)
		real(8), dimension(:,:), allocatable, private		:: rmRotCovQ		! Time series of rotated covariances between velocities and water (m mmol/mol s)
		real(8), dimension(:,:), allocatable, private		:: rmRotCovC		! Time series of rotated covariances between velocities and carbon dioxide (m mmol/mol s)
		! 2) Derived, precision anemometry
		! 3) Derived, common turbulence indicators and energy fluxes
		real(8), dimension(:), allocatable, private			:: rvUstar			! Friction velocity, using both momentum fluxes (always valid) [m/s]
		real(8), dimension(:), allocatable, private			:: rvUstar_3		! Friction velocity, using one momentum flux only (may not be valid; computed only if third rotation angle is non-zero) [m/s]
		real(8), dimension(:), allocatable, private			:: rvH0				! Turbulent flux of sensible heat along the vertical [W/m2]
		real(8), dimension(:), allocatable, private			:: rvHe				! Turbulent flux of latent heat along the vertical [W/m2]
		! 4) Derived, water and carbon dioxide related
		real(8), dimension(:), allocatable, private			:: rvFqMolar		! Water turbulent flux along the vertical [mmol/(m2 s)]
		real(8), dimension(:), allocatable, private			:: rvFqMass			! Water turbulent flux along the vertical [mg/(m2 s)]
		real(8), dimension(:), allocatable, private			:: rvFcMolar		! Carbon dioxide turbulent flux along the vertical [mmol/(m2 s)]
		real(8), dimension(:), allocatable, private			:: rvFcMass			! Carbon dioxide turbulent flux along the vertical [mg/(m2 s)]
	contains
		procedure	:: clean			=> ec_Clean					! Make an EddyCovData object "clean", that is, with vectors unallocated and status logicals .false.
		procedure	:: reserve	 		=> ec_Allocate				! Reserve workspace for vectors (all types)
		procedure	:: dump				=> ec_Dump					! Print contents of an EddyCovData object to screen (mainly for testing)
		procedure	:: getSize			=> ec_getSize				! Get allocated size of an EddyCovData object
		procedure	:: getAvgTime		=> ec_getAvgTime			! Get averaging time (as it is)
		procedure	:: getNumValidInput	=> ec_getNumValidInput		! Count number of valid data in an EddyCovData object
		procedure	:: getNumData		=> ec_getNumData			! Get a number of valid data used to form any mean value
		procedure	:: getInputData		=> ec_getInputData			! Get a copy of input vectors
		procedure	:: getWindVector	=> ec_getWindVector			! Get a copy of wind vector
		procedure	:: getCovWind		=> ec_GetCovWind			! Get values from non-rotated velocity covariances (all)
		procedure	:: getInputGases	=> ec_getInputGases			! Get a copy of input gases vectors
		procedure	:: getOutputData	=> ec_getOutputData			! Get a copy of output vectors
		procedure	:: getCovT			=> ec_GetCovT				! Get values from non-rotated velocity-temperature covariances
		procedure	:: getVarT			=> ec_GetVarT				! Get values from temperature variance
		procedure	:: getRotAngles		=> ec_GetRotAngles			! Get rotation angles
		procedure	:: getUstar			=> ec_GetUstar				! Get friction velocity (according to the two most common definitions)
		procedure	:: getOutputGases	=> ec_getOutputGases		! Get a copy of output gas vectors
		procedure	:: getRotCovVel		=> ec_GetRotCovVel			! Get values from rotated velocity covariances (only those at row i, column j)
		procedure	:: getRotCovWind	=> ec_GetRotCovWind			! Get values from rotated velocity covariances (all)
		procedure	:: getRotCovT		=> ec_GetRotCovT			! Get values from rotated velocity-temperature covariance on direction j (j=1 == X, j=2 == Y, j = 3 == Z)
		procedure	:: getRotCovTemp	=> ec_GetRotCovTemp			! Get values from rotated velocity-temperature covariances
		procedure	:: getRotCovWater	=> ec_GetRotCovWater		! Get values from rotated velocity-water vapor covariances
		procedure	:: getRotCovCo2		=> ec_GetRotCovCo2			! Get values from rotated velocity-carbon dioxide covariances
		procedure	:: getWind			=> ec_GetWind				! Get wind in (Vel,Dir,W) form
		procedure	:: getTemp			=> ec_GetTemp				! Get values from temperature vector
		procedure	:: getH2O			=> ec_GetH2o				! Get water input vectors
		procedure	:: getH2OFluxes		=> ec_GetH2oFluxes			! Get water fluxes vectors
		procedure	:: getCO2Fluxes		=> ec_GetCo2Fluxes			! Get carbon dioxide fluxes vectors
		procedure	:: getCO2			=> ec_GetCo2				! Get carbon dioxide vectors
		procedure	:: getHeatFluxes	=> ec_GetHeatFluxes			! Get heat fluxes vectors
		procedure	:: createEmpty		=> ec_CreateEmpty			! Create an empty EddyCovData object, that is, with allocated vectors but .false. status logicals; mainly for multi-hour e.c. sets
		procedure	:: isClean			=> ec_IsClean				! Check whether an EddyCovData object is clean
		procedure	:: isEmpty			=> ec_IsEmpty				! Check whether an EddyCovData object is empty
		procedure	:: isReady			=> ec_IsPrimed				! Check whether an EddyCovData object is primed (contains some input)
		procedure	:: isFull			=> ec_IsFilled				! Check whether an EddyCovData object is primed (contains some input and processed data)
		procedure	:: isHourly			=> ec_IsHourly				! Check an EddyCovData object is hourly, or not
		procedure	:: getTimeStamp		=> ec_GetTimeStamp			! Retrieve a copy of the object's internal time stamp
		procedure	:: add				=> ec_AddHourly				! Add a hourly EddyCovData object to an existing multi-hourly one
		procedure	:: process			=> ec_Process				! Perform basic wind and temperature processing
	end type EddyCovData

contains

	! Convert 2D (horizontal) wind from wind-direction to component form
	!
	! Input:
	!
	!	polar :					Two-dimensionl vector, containing wind speed in component 1,
	!							and direction in component 2
	!
	!	interpretation :		Integer optional parameter indicating how wind direction is to
	!							be interpreted. Possible values are:
	!
	!							WCONV_SAME					Input and output refer to the same
	!														convention, whatever is
	!
	!							WCONV_PROVENANCE_TO_FLOW	Input in provenance, output in flow
	!														convention
	!
	!							WCONV_FLOW_TO_PROVENANCE	Input in flow, output in provenance
	!														convention
	!
	! Output:
	!
	!	cartesian :				Wind vector in Cartesian components form, with Vx in position 1
	!							and Vy in position 2.
	!
	function PolarToCartesian2(polar, interpretation) result(cartesian)

		! Routine arguments
		real, dimension(2), intent(in)	:: polar				! Wind in polar form (vel=polar(1), dir=polar(2))
		real, dimension(2)				:: cartesian			! Wind in cartesian form (u=cartesian(1), v=cartesian(2))
		integer, intent(in), optional	:: interpretation

		! Locals
		! --none--

		! Convert, taking the desired convention into account
		if(polar(1) > 1.e-6) then
			if(present(interpretation)) then
				if(interpretation == WCONV_SAME) then
					! Same interpretation for input and output: no sign change
					call uvWind(polar(1), polar(2), cartesian(1), cartesian(2))
				elseif(interpretation == WCONV_PROVENANCE_TO_FLOW .or. interpretation == WCONV_FLOW_TO_PROVENANCE) then
					! Different interpretation for input and output: sign change
					call uvWind(polar(1), polar(2) - 180., cartesian(1), cartesian(2))
				else
					! Wrong convention
					cartesian = [NaN, NaN]
				end if
			else
				! Same interpretation for input and output: no sign change
				call uvWind(polar(1), polar(2), cartesian(1), cartesian(2))
			end if
		else
			cartesian = [NaN, NaN]
		end if

	end function PolarToCartesian2


	! Convert 3D wind from wind-direction-vertical to component form
	!
	! Input:
	!
	!	polar :					Three-dimensionl vector, containing wind speed in component 1,
	!							direction in component 2, and vertical wind in component 3
	!
	!	interpretation :		Integer optional parameter indicating how wind direction is to
	!							be interpreted. Possible values are:
	!
	!							WCONV_SAME					Input and output refer to the same
	!														convention, whatever is
	!
	!							WCONV_PROVENANCE_TO_FLOW	Input in provenance, output in flow
	!														convention
	!
	!							WCONV_FLOW_TO_PROVENANCE	Input in flow, output in provenance
	!														convention
	!
	! Output:
	!
	!	cartesian :				Wind vector in Cartesian components form, with Vx in position 1
	!							Vy in position 2, and Vz in position 3.
	!
	function PolarToCartesian3(polar, interpretation) result(cartesian)

		! Routine arguments
		real, dimension(3), intent(in)	:: polar				! Wind in polar form (vel=polar(1), dir=polar(2), w=polar(3))
		real, dimension(3)				:: cartesian			! Wind in cartesian form (u=cartesian(1), v=cartesian(2), w=cartesian(3))
		integer, intent(in), optional	:: interpretation

		! Locals
		! --none--

		! Convert, taking the desired convention into account
		if(polar(1) > 1.e-6) then
			if(present(interpretation)) then
				if(interpretation == WCONV_SAME) then
					! Same interpretation for input and output: no sign change
					call uvWind(polar(1), polar(2), cartesian(1), cartesian(2))
					cartesian(3) = polar(3)
				elseif(interpretation == WCONV_PROVENANCE_TO_FLOW .or. interpretation == WCONV_FLOW_TO_PROVENANCE) then
					! Different interpretation for input and output: sign change
					call uvWind(polar(1), polar(2) - 180., cartesian(1), cartesian(2))
					cartesian(3) = polar(3)
				else
					! Wrong convention
					cartesian = [NaN, NaN, polar(3)]
				end if
			else
				! Same interpretation for input and output: no sign change
				call uvWind(polar(1), polar(2), cartesian(1), cartesian(2))
			end if
		else
			cartesian = [NaN, NaN, polar(3)]
		end if

	end function PolarToCartesian3


	! Convert 2D (horizontal) wind from component to wind-direction form
	!
	! Input:
	!
	!	cartesian :				Two-dimensionl vector, containing Vx component in component 1,
	!							and Vy in component 2
	!
	!	interpretation :		Integer optional parameter indicating how wind direction is to
	!							be interpreted. Possible values are:
	!
	!							WCONV_SAME					Input and output refer to the same
	!														convention, whatever is
	!
	!							WCONV_PROVENANCE_TO_FLOW	Input in provenance, output in flow
	!														convention
	!
	!							WCONV_FLOW_TO_PROVENANCE	Input in flow, output in provenance
	!														convention
	!
	! Output:
	!
	!	polar :					Wind vector in polar components form, with wind speed in position 1
	!							and wind direction in position 2.
	!
	function CartesianToPolar2(cartesian, interpretation) result(polar)

		! Routine arguments
		real, dimension(2), intent(in)	:: cartesian			! Wind in cartesian form (u=cartesian(1), v=cartesian(2))
		real, dimension(2)				:: polar				! Wind in polar form (vel=polar(1), dir=polar(2))
		integer, intent(in), optional	:: interpretation

		! Locals
		! --none--

		! Convert, taking the desired convention into account
		if(dot_product(cartesian, cartesian) > 1.e-6) then
			if(present(interpretation)) then
				if(interpretation == WCONV_SAME) then
					! Same interpretation for input and output: no sign change
					call veldirWind(cartesian(1), cartesian(2), polar(1), polar(2))
				elseif(interpretation == WCONV_PROVENANCE_TO_FLOW .or. interpretation == WCONV_FLOW_TO_PROVENANCE) then
					! Different interpretation for input and output: sign change
					call veldirWind(-cartesian(1), -cartesian(2), polar(1), polar(2))
				else
					! Wrong convention
					polar = [NaN, NaN]
				end if
			else
				! Same interpretation for input and output: no sign change
				call veldirWind(cartesian(1), cartesian(2), polar(1), polar(2))
			end if
		else
			polar = [0., NaN]
		end if

	end function CartesianToPolar2


	! Convert 3D wind from component to wind-direction form
	!
	! Input:
	!
	!	cartesian :				Three-dimensionl vector, containing Vx component in component 1,
	!							Vy in component 2 and Vz in component 3
	!
	!	interpretation :		Integer optional parameter indicating how wind direction is to
	!							be interpreted. Possible values are:
	!
	!							WCONV_SAME					Input and output refer to the same
	!														convention, whatever is
	!
	!							WCONV_PROVENANCE_TO_FLOW	Input in provenance, output in flow
	!														convention
	!
	!							WCONV_FLOW_TO_PROVENANCE	Input in flow, output in provenance
	!														convention
	!
	! Output:
	!
	!	polar :					Wind vector in polar components form, with wind speed in position 1,
	!							wind direction in position 2 and Vz in position 3.
	!
	function CartesianToPolar3(cartesian, interpretation) result(polar)

		! Routine arguments
		real, dimension(3), intent(in)	:: cartesian			! Wind in cartesian form (u=cartesian(1), v=cartesian(2), w=cartesian(3))
		real, dimension(3)				:: polar				! Wind in polar form (vel=polar(1), dir=polar(2), w=polar(3))
		integer, intent(in), optional	:: interpretation

		! Locals
		! --none--

		! Convert, taking the desired convention into account
		if(dot_product(cartesian(1:2), cartesian(1:2)) > 1.e-6) then
			if(present(interpretation)) then
				if(interpretation == WCONV_SAME) then
					! Same interpretation for input and output: no sign change
					call veldirWind(cartesian(1), cartesian(2), polar(1), polar(2))
					polar(3) = cartesian(3)
				elseif(interpretation == WCONV_PROVENANCE_TO_FLOW .or. interpretation == WCONV_FLOW_TO_PROVENANCE) then
					! Different interpretation for input and output: sign change
					call veldirWind(-cartesian(1), -cartesian(2), polar(1), polar(2))
					polar(3) = cartesian(3)
				else
					! Wrong convention
					polar = [NaN, NaN, cartesian(3)]
				end if
			else
				! Same interpretation for input and output: no sign change
				call veldirWind(cartesian(1), cartesian(2), polar(1), polar(2))
			end if
		else
			polar = [0., NaN, cartesian(3)]
		end if

	end function CartesianToPolar3


	function ClassVelScalar(vel, rvVel) result(iClass)

		! Routine arguments
		real, intent(in)				:: vel			! Wind speed to classify
		real, dimension(:), intent(in)	:: rvVel		! Vector, containing upper class limits in increasing order
		integer							:: iClass		! Speed class to which the wind belongs (-9999 if not assignable)

		! Locals
		integer		:: n
		integer		:: i

		! Check class limit validity
		if(size(rvVel) <= 0.) then
			iClass = -9999
			return
		end if
		if(all(.invalid.rvVel)) then
			iClass = -9999
			return
		end if

		! Check something is to be made: leave, if not
		if(.invalid.vel) then
			iClass = -9999
			return
		end if

		! Check added on input vector size
		if(size(rvVel) <= 0) then
			iClass = -9999
			return
		end if

		! Perform a simple table lookup
		n = size(rvVel)
		do i = 1, n
			if(vel <= rvVel(i)) then
				iClass = i
				return
			end if
		end do

		! Execution reaches this point if no match is found, so
		iClass = n + 1

	end function ClassVelScalar


	function ClassVelVector(vel, rvVel) result(ivClass)

		! Routine arguments
		real, dimension(:), intent(in)	:: vel			! Wind speed to classify
		real, dimension(:), intent(in)	:: rvVel		! Vector, containing upper class limits in increasing order
		integer, dimension(size(vel))	:: ivClass		! Speed class to which the wind belongs (-9999 if not assignable)

		! Locals
		integer		:: n
		integer		:: i, j

		! Check class limit validity
		if(size(rvVel) <= 0.) then
			ivClass = -9999
			return
		end if
		if(all(.invalid.rvVel)) then
			ivClass = -9999
			return
		end if

		! Main loop: iterate over speed values
		do j = 1, size(vel)

			! Check class can be assigned
			if(.invalid.vel(j)) then
				ivClass(j) = -9999
			else

				! Perform a simple table lookup
				n = size(rvVel)
				ivClass(j) = n + 1
				do i = 1, n
					if(vel(j) <= rvVel(i)) then
						ivClass(j) = i
						exit
					end if
				end do

			end if

		end do

	end function ClassVelVector


	function ClassDirScalar(dir, iNumClasses, iClassType) result(iClass)

		! Routine arguments
		real, intent(in)				:: dir				! Wind direction to classify (°)
		integer, intent(in)				:: iNumClasses		! Number of desired classes
		integer, intent(in), optional	:: iClassType		! Class type (WDCLASS_ZERO_CENTERED (default): first class is zero-centered; WDCLASS_ZERO_BASED: first class starts at zero)
		integer							:: iClass			! Direction class to which the wind belongs (-9999 if no class is assignable)

		! Locals
		real	:: classWidth
		real	:: d
		integer	:: iClsType

		! Check something is to be made: leave, if not
		if(ieee_is_nan(dir)) then
			iClass = -9999
			return
		end if

		! If missing 'iClassType' assign default, otherwise get it
		if(present(iClassType)) then
			iClsType = iClassType
		else
			iClsType = WDCLASS_ZERO_CENTERED
		end if

		! Compute the fixed-size class width, and in case of zero-centere classes use it to adjust direction
		if(iNumClasses <= 0) then
			iClass = -9999
			return
		end if
		classWidth = 360. / iNumClasses
		d = dir
		if(iClsType == WDCLASS_ZERO_CENTERED) d = d + classWidth / 2.

		! Adjust wind direction to the range 0-360
		d = mod(d, 360.)
		if(d < 0.) d = d + 360.

		! Assign class by division
		iClass = floor(d / classWidth) + 1

	end function ClassDirScalar


	function ClassDirVector(dir, iNumClasses, iClassType) result(ivClass)

		! Routine arguments
		real, dimension(:), intent(in)	:: dir				! Wind direction to classify (°)
		integer, intent(in)				:: iNumClasses		! Number of desired classes
		integer, intent(in), optional	:: iClassType		! Class type (WDCLASS_ZERO_CENTERED (default): first class is zero-centered; WDCLASS_ZERO_BASED: first class starts at zero)
		integer, dimension(size(dir))	:: ivClass			! Direction class to which the wind belongs (-9999 if no class is assignable)

		! Locals
		real						:: classWidth
		real, dimension(size(dir))	:: d
		integer						:: iClsType

		! Check something is to be made: leave, if not
		if(iNumClasses <= 0) then
			ivClass = -9999
			return
		end if

		! If missing 'iClassType' assign default, otherwise get it
		if(present(iClassType)) then
			iClsType = iClassType
		else
			iClsType = WDCLASS_ZERO_CENTERED
		end if

		! Compute the fixed-size class width, and in case of zero-centere classes use it to adjust direction
		classWidth = 360. / iNumClasses
		d = dir
		if(iClsType == WDCLASS_ZERO_CENTERED) d = d + classWidth / 2.
		where(ieee_is_nan(d))

			ivClass = -9999

		elsewhere

			! Adjust wind direction to the range 0-360
			d = mod(d, 360.)
			where(d < 0.)
				d = d + 360.
			endwhere

			! Assign class by division
			ivClass = floor(d / classWidth) + 1

		end where

	end function ClassDirVector


	function VectorDirVel(rvVel, rvDir) result(polar)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvVel
		real, dimension(:), intent(in)	:: rvDir
		real, dimension(2)				:: polar		! [vel,dir]

		! Locals
		real, dimension(size(rvVel))	:: rvU
		real, dimension(size(rvVel))	:: rvV
		integer							:: n
		real							:: rU
		real							:: rV

		! Check input parameters make sense
		if(size(rvVel) /= size(rvDir)) then
			polar = [NaN, NaN]
			return
		end if

		! Transform horizontal wind from polar to Cartesian form. In this case
		! it is irrelevant whether the wind directio interpretation is of
		! flow or provenance convention: the transformed vectors will be
		! back-transformed by the same interpretation.
		rvU = rvVel * sin(rvDir * ToRad)
		rvV = rvVel * cos(rvDir * ToRad)

		! Compute the Cartesian average of wind vectors
		n = count(.not.ieee_is_nan(rvU))
		if(n > 0) then
			! At least one element: compute the vector mean
			rU = sum(rvU, mask=.not.ieee_is_nan(rvU)) / n
			rV = sum(rvV, mask=.not.ieee_is_nan(rvU)) / n
		else
			rU = NaN
			rV = NaN
		end if

		! Convert the Cartesian average to mean wind in polar form
		polar = [sqrt(rU**2 + rV**2), atan2(rU,rV)*ToDeg]
		if(polar(2) < 0) polar(2) = polar(2) + 360.0

	end function VectorDirVel


	function ScalarVel(rvVel) result(vel)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvVel
		real							:: vel

		! Locals
		integer	:: n

		! Compute the wind scalar speed
		n = count(.not.ieee_is_nan(rvVel))
		if(n > 0) then
			! At least one element: compute the scalar mean
			vel = sum(rvVel, mask=.not.ieee_is_nan(rvVel)) / n
		else
			vel = NaN
		end if

	end function ScalarVel


	function UnitDir(rvDir) result(dir)

		! Routine arguments
		real, dimension(:), intent(in)	:: rvDir
		real							:: dir

		! Locals
		real, dimension(size(rvDir))	:: rvU
		real, dimension(size(rvDir))	:: rvV
		integer							:: n
		real							:: rU
		real							:: rV

		! Transform horizontal wind from polar to Cartesian form. In this case
		! it is irrelevant whether the wind directio interpretation is of
		! flow or provenance convention: the transformed vectors will be
		! back-transformed by the same interpretation.
		rvU = sin(rvDir * ToRad)
		rvV = cos(rvDir * ToRad)

		! Compute the Cartesian average of wind vectors
		n = count(.not.ieee_is_nan(rvU))
		if(n > 0) then
			! At least one element: compute the vector mean
			rU = sum(rvU, mask=.not.ieee_is_nan(rvU)) / n
			rV = sum(rvV, mask=.not.ieee_is_nan(rvU)) / n
		else
			rU = NaN
			rV = NaN
		end if

		! Convert the Cartesian average to mean wind in polar form
		dir = atan2(rU,rV)*ToDeg
		if(dir < 0.) dir = dir + 360.

	end function UnitDir


	! Compute the joint frequency function of wind speed and direction, that is, the
	! "wind rose" as it is commonly named.
	!
	! In principle, in place of wind speed any other scalar may be used - for example
	! a pollutant concentration: in this case a, say, concentration rose is obtained.
	!
	! The graphical rendering of the wind (concentration , ...) rose is not among
	! the scopes of pbl_met, but nevertheless you may find excellent routines and
	! packages to accomplish this task in the open source.
	function WindRose(vel, dir, rvVel, iNumClasses, iClassType, rmWindRose) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)					:: vel			! Wind speed observations (m/s)
		real, dimension(:), intent(in)					:: dir			! Wind direction observations (°)
		real, dimension(:), intent(in)					:: rvVel		! Wind speed class limits as in ClassVel (m/s)
		integer, intent(in)								:: iNumClasses	! Number of direction classes as in ClassDir
		integer, intent(in), optional					:: iClassType	! Type of direction classes as in ClassDir (WDCLASS_ZERO_CENTERED (default), or WDCLASS_ZERO_BASED)
		real, dimension(:,:), allocatable, intent(out)	:: rmWindRose	! Joint frequency table of wind speed and direction, aka "wind rose" (in tabular form)
		integer											:: iRetCode

		! Locals
		integer, dimension(size(vel))	:: ivVelClass
		integer, dimension(size(dir))	:: ivDirClass
		integer							:: i
		integer							:: m
		integer							:: n
		integer							:: l
		real							:: rTotal
		integer							:: iDirClassType

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check data vectors have the same size
		l = size(vel)
		if(size(dir) /= l) then
			iRetCode = 1
			return
		end if

		! Check classification parameters, and use it to reserve workspace if correct
		if(size(rvVel) <= 0) then
			iRetCode = 2
			return
		end if
		m = size(rvVel) + 1
		if(iNumClasses <= 0) then
			iRetCode = 3
			return
		end if
		n = iNumClasses
		if(allocated(rmWindRose)) deallocate(rmWindRose)
		allocate(rmWindRose(m,n))

		! Clean up, and check the call makes sense
		rmWindRose = 0.

		! Get direction class type
		if(present(iClassType)) then
			iDirClassType = iClassType
		else
			iDirClassType = WDCLASS_ZERO_CENTERED
		end if

		! Classify wind speed and direction
		ivVelClass = ClassVelVector(vel, rvVel)
		ivDirClass = ClassDirVector(dir, iNumClasses, iDirClassType)

		! Count occurrences in any class
		do i = 1, size(vel)
			if(ivVelClass(i) > 0 .and. ivDirClass(i) > 0) &
				rmWindRose(ivVelClass(i),ivDirClass(i)) = rmWindRose(ivVelClass(i),ivDirClass(i)) + 1.
		end do

		! Convert counts to frequency
		rTotal = sum(rmWindRose)	! That is, number of valid data
		if(rTotal > 0.) rmWindRose = rmWindRose / rTotal

	end function WindRose


	function CompareWindRoses( &
		vel1, dir1, &
		vel2, dir2, &
		rvVel, iNumClasses, iClassType, &
		rmWindRose1, rmWindRose2, &
		rProb, rChiSquareOut, iDegreesOfFreedomOut &
	) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)					:: vel1					! First wind speed observations (m/s)
		real, dimension(:), intent(in)					:: dir1					! First wind direction observations (°)
		real, dimension(:), intent(in)					:: vel2					! Second wind speed observations (m/s)
		real, dimension(:), intent(in)					:: dir2					! Second wind direction observations (°)
		real, dimension(:), intent(in)					:: rvVel				! Wind speed class limits as in ClassVel (m/s)
		integer, intent(in)								:: iNumClasses			! Number of direction classes as in ClassDir
		integer, intent(in), optional					:: iClassType			! Type of direction classes as in ClassDir (WDCLASS_ZERO_CENTERED (default), or WDCLASS_ZERO_BASED)
		real, dimension(:,:), allocatable, intent(out)	:: rmWindRose1			! First joint frequency table of wind speed and direction, aka "wind rose" (in tabular form)
		real, dimension(:,:), allocatable, intent(out)	:: rmWindRose2			! Second joint frequency table of wind speed and direction, aka "wind rose" (in tabular form)
		real, intent(out)								:: rProb				! Probability associated with Chi-square equality of distribution test, applied to the two wind roses
		real, intent(out), optional						:: rChiSquareOut		! Chi square sum
		integer, intent(out), optional					:: iDegreesOfFreedomOut	! Chi square degrees of freedom
		integer											:: iRetCode

		! Locals
		integer	:: i, j
		integer	:: iErrCode
		integer	:: iDegreesOfFreedom
		real	:: rChiSquare
		real	:: R, S, RS, SR

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Compute the two wind roses with respect to the same classes
		iErrCode = WindRose(vel1, dir1, rvVel, iNumClasses, iClassType, rmWindRose1)
		if(iErrCode /= 0) then
			if(allocated(rmWindRose1)) deallocate(rmWindRose1)
			if(allocated(rmWindRose2)) deallocate(rmWindRose2)
			rProb = NaN
			iRetCode = 1
			return
		end if
		iErrCode = WindRose(vel2, dir2, rvVel, iNumClasses, iClassType, rmWindRose2)
		if(iErrCode /= 0) then
			if(allocated(rmWindRose1)) deallocate(rmWindRose1)
			if(allocated(rmWindRose2)) deallocate(rmWindRose2)
			rProb = NaN
			iRetCode = 1
			return
		end if

		! Rescale the wind roses from fraction to count form
		rmWindRose1 = rmWindRose1 * size(vel1)
		rmWindRose2 = rmWindRose2 * size(vel2)

		! Compute the coefficients adjusting for different wind vector sizes
		R  = real(size(vel1))
		S  = real(size(vel2))
		RS = sqrt(R/S)
		SR = sqrt(S/R)

		! Compute chi-square variable
		iDegreesOfFreedom = -1	! Take into account the normalization made on wind roses expressed as fraction
		rChiSquare        =  0.
		do i = 1, size(rmWindRose1, dim=1)
			do j = 1, size(rmWindRose1, dim=2)
				if(rmWindRose1(i,j) > 0. .or. rmWindRose2(i,j) > 0.) then
					iDegreesOfFreedom = iDegreesOfFreedom + 1
					rChiSquare = rChiSquare + (SR*rmWindRose1(i,j) - RS*rmWindRose2(i,j))**2 / (rmWindRose1(i,j) + rmWindRose2(i,j))
				end if
			end do
		end do

		! Calculate probability
		rProb = 1. - gammaP(0.5*iDegreesOfFreedom, 0.5*rChiSquare)

		! Return auxiliary quantities, if desired
		if(present(rChiSquareOut))        rChiSquareOut = rChiSquare
		if(present(iDegreesOfFreedomOut)) iDegreesOfFreedomOut = iDegreesOfFreedom

	end function CompareWindRoses


	function VelDirMean(vel, dir, scalar, rvVel, iNumClasses, iClassType, rmMean) result(iRetCode)

		! Routine arguments
		real, dimension(:), intent(in)					:: vel			! Wind speed observations (m/s)
		real, dimension(:), intent(in)					:: dir			! Wind direction observations (°)
		real, dimension(:), intent(in)					:: scalar		! Any scalar quantity (any unit; invalid values as NaN)
		real, dimension(:), intent(in)					:: rvVel		! Wind speed class limits as in ClassVel (m/s)
		integer, intent(in)								:: iNumClasses	! Number f direction classes as in ClassDir
		integer, intent(in)								:: iClassType	! Type of direction classes as in ClassDir
		real, dimension(:,:), allocatable, intent(out)	:: rmMean		! Mean of scalar according to wind speed and direction classes
		integer											:: iRetCode

		! Locals
		integer, dimension(size(vel))			:: ivVelClass
		integer, dimension(size(dir))			:: ivDirClass
		integer									:: i
		integer, dimension(:,:), allocatable	:: imNumValues

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Clean up, and check the call makes sense
		if(size(dir) <= 0 .or. size(vel) <= 0 .or. size(scalar) <= 0) then
			iRetCode = 1
			return
		end if
		if(size(dir) /= size(vel) .or. size(scalar) /= size(vel)) then
			iRetCode = 2
			return
		end if
		if(size(rvVel) <= 0 .or. iNumClasses <= 0) then
			iRetCode = 3
			return
		end if
		if(allocated(rmMean)) deallocate(rmMean)
		allocate(rmMean(size(rvVel)+1,iNumClasses))
		allocate(imNumValues(size(rvVel)+1,iNumClasses))

		! Classify wind speed and direction
		ivVelClass = ClassVelVector(vel, rvVel)
		ivDirClass = ClassDirVector(dir, iNumClasses, iClassType)

		! Count occurrences in any class
		rmMean      = 0.
		imNumValues = 0
		do i = 1, size(vel)
			if(ivVelClass(i) > 0 .and. ivDirClass(i) > 0 .and. (.not.ieee_is_nan(scalar(i)))) then
				rmMean(ivVelClass(i),ivDirClass(i))      = rmMean(ivVelClass(i),ivDirClass(i)) + scalar(i)
				imNumValues(ivVelClass(i),ivDirClass(i)) = imNumValues(ivVelClass(i),ivDirClass(i)) + 1
			end if
		end do

		! Convert counts to means
		where(imNumValues > 0)
			rmMean = rmMean / imNumValues
		elsewhere
			rmMean = NaN
		end where

	end function VelDirMean


	function VelMean(vel, scalar, rvVel) result(rvMean)

		! Routine arguments
		real, dimension(:), intent(in)	:: vel			! Wind speed observations (m/s)
		real, dimension(:), intent(in)	:: scalar		! Any scalar quantity (any unit; invalid values as NaN)
		real, dimension(:), intent(in)	:: rvVel		! Wind speed class limits as in ClassVel (m/s)
		real, dimension(size(rvVel)+1)	:: rvMean		! Mean of scalar according to wind speed and direction classes

		! Locals
		integer, dimension(size(vel))		:: ivVelClass
		integer, dimension(size(rvVel)+1)	:: ivNumValues
		integer								:: i

		! Clean up, and check the call makes sense
		rvMean = NaN
		ivNumValues = 0
		if(size(scalar) /= size(vel)) return

		! Classify wind speed and direction
		ivVelClass = ClassVelVector(vel, rvVel)

		! Count occurrences in any class
		rvMean = 0.
		do i = 1, size(vel)
			if(ivVelClass(i) > 0 .and. (.not.ieee_is_nan(scalar(i)))) then
				rvMean(ivVelClass(i)) = rvMean(ivVelClass(i)) + scalar(i)
				ivNumValues(ivVelClass(i)) = ivNumValues(ivVelClass(i)) + 1
			end if
		end do

		! Convert counts to means
		where(ivNumValues > 0)
			rvMean = rvMean / ivNumValues
		elsewhere
			rvMean = NaN
		end where

	end function VelMean


	function DirMean(dir, scalar, iNumClasses, iClassType) result(rvMean)

		! Routine arguments
		real, dimension(:), intent(in)	:: dir			! Wind direction observations (°)
		real, dimension(:), intent(in)	:: scalar		! Any scalar quantity (any unit; invalid values as NaN)
		integer, intent(in)				:: iNumClasses	! Number f direction classes as in ClassDir
		integer, intent(in)				:: iClassType	! Type of direction classes as in ClassDir
		real, dimension(iNumClasses)	:: rvMean		! Mean of scalar according to wind speed and direction classes

		! Locals
		integer, dimension(size(dir))		:: ivDirClass
		integer, dimension(iNumClasses)		:: ivNumValues
		integer								:: i

		! Clean up, and check the call makes sense
		rvMean = NaN
		ivNumValues = 0
		if(size(scalar) /= size(dir)) return

		! Classify wind speed and direction
		ivDirClass = ClassDirVector(dir, iNumClasses, iClassType)

		! Count occurrences in any class
		rvMean = 0.
		do i = 1, size(dir)
			if(ivDirClass(i) > 0 .and. (.not.ieee_is_nan(scalar(i)))) then
				rvMean(ivDirClass(i)) = rvMean(ivDirClass(i)) + scalar(i)
				ivNumValues(ivDirClass(i)) = ivNumValues(ivDirClass(i)) + 1
			end if
		end do

		! Convert counts to means
		where(ivNumValues > 0)
			rvMean = rvMean / ivNumValues
		elsewhere
			rvMean = NaN
		end where

	end function DirMean


	function sd_BuildFromVectors(this, rvTimeStamp, rvU, rvV, rvW, rvT, rvQ, rvC) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(out)				:: this
		real(8), dimension(:), intent(in)			:: rvTimeStamp	! Time stamp, in Epoch new form
		real, dimension(:), intent(in)				:: rvU			! Eastward wind component (m/s)
		real, dimension(:), intent(in)				:: rvV			! Northward wind component (m/s)
		real, dimension(:), intent(in)				:: rvW			! Verticalward wind component (m/s)
		real, dimension(:), intent(in)				:: rvT			! Sonic temperature (°C)
		real, dimension(:), intent(in), optional	:: rvQ			! Water vapor (mmol/mol)
		real, dimension(:), intent(in), optional	:: rvC			! Carbon dioxide (mmol/mol) (if present, also water vapor must be present)
		integer										:: iRetCode

		! Locals
		integer	::nstamp, nu, nv, nw, nt, nq, nc, n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Get and check vector sizes
		nstamp = size(rvTimeStamp)
		nu     = size(rvU)
		nv     = size(rvV)
		nw     = size(rvW)
		nt     = size(rvT)
		if(maxval(abs(nstamp-[nu,nv,nw,nt])) > 0) then
			! Just a fancy way to pack all together the equal-size comparisons: if all are equal, then the differences
			! (componentwise) between [nu,nv,nw,nt] and nstamp are all zero, and then their absolute maximum is zero, too.
			! Conversely, if the absolute maximum is > 0 then at least one of the nu,nv,nw,nt differs from nstamp.
			! Notice in this case the routine does nothing on dthe SonicData structure, which is left unchanged.
			iRetCode = 1
			return
		end if
		n = nstamp
		! Post-condition: nstamp == nu == nv == nw == nt == n

		! Get and check optional vector sizes
		if(present(rvQ)) then
			nq = size(rvQ)
			if(nq /= n) then
				iRetCode = 1
				return
			end if
			if(present(rvC)) then
				nc = size(rvC)
				if(nc /= n) then
					iRetCode = 1
					return
				end if
			end if
		end if

		! Reserve workspace
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvU))         deallocate(this % rvU)
		if(allocated(this % rvV))         deallocate(this % rvV)
		if(allocated(this % rvW))         deallocate(this % rvW)
		if(allocated(this % rvT))         deallocate(this % rvT)
		if(allocated(this % rvVel))       deallocate(this % rvVel)
		if(allocated(this % rvVel3D))     deallocate(this % rvVel3D)
		if(allocated(this % rvUnitU))     deallocate(this % rvUnitU)
		if(allocated(this % rvUnitV))     deallocate(this % rvUnitV)
		if(allocated(this % rvQ))         deallocate(this % rvQ)
		if(allocated(this % rvC))         deallocate(this % rvC)
		allocate(this % rvTimeStamp(n))
		allocate(this % rvU(n))
		allocate(this % rvV(n))
		allocate(this % rvW(n))
		allocate(this % rvT(n))
		if(present(rvQ)) allocate(this % rvQ(n))
		if(present(rvC)) allocate(this % rvC(n))

		! Assign values
		this % rvTimeStamp = rvTimeStamp
		this % rvU         = rvU
		this % rvV         = rvV
		this % rvW         = rvW
		this % rvT         = rvT
		this % rvVel       = sqrt(rvU**2 + rvV**2)
		this % rvVel3D     = sqrt(rvU**2 + rvV**2 + rvW**2)
		this % rvUnitU     = rvU / this % rvVel
		this % rvUnitV     = rvV / this % rvVel
		if(present(rvQ)) this % rvQ = rvQ
		if(present(rvQ)) this % rvC = rvC
		this % isValid     = .true.

	end function sd_BuildFromVectors


	function sd_GetVectors(this, rvTimeStamp, rvU, rvV, rvW, rvT, rvQ, rvC) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(in)							:: this
		real(8), dimension(:), allocatable, intent(out)			:: rvTimeStamp	! Time stamp, in Epoch new form
		real, dimension(:), allocatable, intent(out)			:: rvU			! Eastward wind component (m/s)
		real, dimension(:), allocatable, intent(out)			:: rvV			! Northward wind component (m/s)
		real, dimension(:), allocatable, intent(out)			:: rvW			! Verticalward wind component (m/s)
		real, dimension(:), allocatable, intent(out)			:: rvT			! Sonic temperature (°C)
		real, dimension(:), allocatable, intent(out), optional	:: rvQ			! Water vapor (mmol/mol)
		real, dimension(:), allocatable, intent(out), optional	:: rvC			! Carbon dioxide (mmol/mol)
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume succes (will falsify on failure)
		iRetCode = 0

		! Get and check vector sizes
		if(.not.allocated(this % rvTimeStamp)) then
			iRetCode = 1
			return
		end if
		n = size(this % rvTimeStamp)
		if(n <= 0) then
			iRetCode = 2
			return
		end if

		! Reserve workspace
		if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
		if(allocated(rvU))         deallocate(rvU)
		if(allocated(rvV))         deallocate(rvV)
		if(allocated(rvW))         deallocate(rvW)
		if(allocated(rvT))         deallocate(rvT)
		allocate(rvTimeStamp(n))
		allocate(rvU(n))
		allocate(rvV(n))
		allocate(rvW(n))
		allocate(rvT(n))
		if(present(rvQ)) then
			if(allocated(rvQ))     deallocate(rvQ)
			allocate(rvQ(n))
		end if
		if(present(rvC)) then
			if(allocated(rvC))     deallocate(rvC)
			allocate(rvC(n))
		end if

		! Assign values
		rvTimeStamp = this % rvTimeStamp
		rvU         = this % rvU
		rvV         = this % rvV
		rvW         = this % rvW
		rvT         = this % rvT
		if(present(rvQ)) rvQ = this % rvQ
		if(present(rvC)) rvC = this % rvC

	end function sd_GetVectors


	function sd_GetSpeed(this, rvVel, rvVel3D) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(in)							:: this
		real(8), dimension(:), allocatable, intent(out)			:: rvVel	! Instant horizontal speed
		real(8), dimension(:), allocatable, intent(out)			:: rvVel3D	! Instant total speed
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume succes (will falsify on failure)
		iRetCode = 0

		! Get and check vector sizes
		if(.not.allocated(this % rvTimeStamp)) then
			iRetCode = 1
			return
		end if
		n = size(this % rvTimeStamp)
		if(n <= 0) then
			iRetCode = 2
			return
		end if

		! Reserve workspace
		if(allocated(rvVel))   deallocate(rvVel)
		if(allocated(rvVel3D)) deallocate(rvVel3D)
		allocate(rvVel(n))
		allocate(rvVel3D(n))

		! Assign values
		rvVel   = this % rvVel
		rvVel3D = this % rvVel3D

	end function sd_GetSpeed


	function sd_ReadSonicLib(this, iLUN, sFileName, iOS) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(out)	:: this
		integer, intent(in)				:: iLUN
		character(len=*), intent(in)	:: sFileName
		integer, intent(in)				:: iOS
		integer							:: iRetCode

		! Locals
		integer				:: iErrCode
		logical				:: lExist
		character(len=15)	:: sBaseName
		character(len=64)	:: sBuffer
		integer				:: iPos
		type(DateTime)		:: tStamp
		real(8)				:: rTimeBase
		integer				:: iNumData
		logical				:: lPresentQ = .false.
		logical				:: lPresentC = .false.
		integer				:: iOptions
		integer				:: i
		integer				:: iYear, iMonth, iDay, iHour

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check file exists
		inquire(file=sFileName, exist=lExist)
		if(.not.lExist) then
			iRetCode = 1
			return
		end if

		! Check file name to be a valid SonicLib, and obtain its time base
		sBaseName = baseName(sFileName, iOS)
		if(len_trim(sBaseName) /= 15) then
			iRetCode = 2
			return
		end if
		read(sBaseName, "(i4,2i2,1x,i2)", iostat=iErrCode) iYear, iMonth, iDay, iHour
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		open(iLUN, file=sFileName, status='old', action='read', iostat=iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 4
			close(iLUN)
			return
		end if
		tStamp = DateTime(iYear, iMonth, iDay, iHour, 0, 0.d0)
		rTimeBase = tStamp % toEpoch()

		! Get and parse header line, to see whether H2O and CO2 are also present
		read(iLUN, "(a)", iostat=iErrCode) sBuffer
		if(iErrCode /= 0) then
			iRetCode = 5
			return
		end if
		if(scan(sBuffer, "q") > 0) lPresentQ = .true.
		if(scan(sBuffer, "c") > 0) lPresentC = .true.
		if(lPresentC .and. .not. lPresentQ) then
			iRetCode = 6
			return
		end if

		! Count data and reserve workspace
		iNumData = 0
		do
			read(iLUN, "(a)", iostat=iErrCode) sBuffer
			if(iErrCode /= 0) exit
			iNumData = iNumData + 1
		end do
		if(iNumData <= 0) then
			iRetCode = 7
			close(iLUN)
			return
		end if
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvU)) deallocate(this % rvU)
		if(allocated(this % rvV)) deallocate(this % rvV)
		if(allocated(this % rvW)) deallocate(this % rvW)
		if(allocated(this % rvT)) deallocate(this % rvT)
		if(allocated(this % rvQ)) deallocate(this % rvQ)
		if(allocated(this % rvC)) deallocate(this % rvC)
		allocate(this % rvTimeStamp(iNumData))
		allocate(this % rvU(iNumData))
		allocate(this % rvV(iNumData))
		allocate(this % rvW(iNumData))
		allocate(this % rvT(iNumData))
		if(lPresentQ) allocate(this % rvQ(iNumData))
		if(lPresentC) allocate(this % rvC(iNumData))

		! Prepare to read, discerning the case with optional data
		iOptions = 0
		if(lPresentQ) iOptions = 1
		if(lPresentC) iOptions = 2

		! Read actual data
		rewind(iLUN)
		read(iLUN, "(a)") sBuffer	! Skip header line
		do i = 1, iNumData
			if(iOptions == 0) then
				read(iLUN, *) &
					this % rvTimeStamp(i), &
					this % rvU(i), &
					this % rvV(i), &
					this % rvW(i), &
					this % rvT(i)
			elseif(iOptions == 1) then
				read(iLUN, *) &
					this % rvTimeStamp(i), &
					this % rvU(i), &
					this % rvV(i), &
					this % rvW(i), &
					this % rvT(i), &
					this % rvQ(i)
			elseif(iOptions == 2) then
				read(iLUN, *) &
					this % rvTimeStamp(i), &
					this % rvU(i), &
					this % rvV(i), &
					this % rvW(i), &
					this % rvT(i), &
					this % rvQ(i), &
					this % rvC(i)
			end if
		end do
		close(iLUN)

		! Shift the time stamps read (representing second) by the base time,
		! obtaining full time stamps
		this % rvTimeStamp = this % rvTimeStamp + rTimeBase

		! Inform users all was OK
		this % isValid = .true.

	end function sd_ReadSonicLib


	function sd_ReadWindRecorder(this, iLUN, sFileName, iOS, iSonicType) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(out)	:: this
		integer, intent(in)				:: iLUN
		character(len=*), intent(in)	:: sFileName
		integer, intent(in)				:: iOS
		integer, intent(in), optional	:: iSonicType
		integer							:: iRetCode

		! Locals
		integer				:: iErrCode
		logical				:: lExist
		character(len=15)	:: sBaseName
		character(len=64)	:: sBuffer
		integer				:: iPos
		type(DateTime)		:: tStamp
		real(8)				:: rTimeBase
		integer				:: iNumData
		integer				:: i
		integer				:: iYear, iMonth, iDay, iHour
		integer				:: iSonic
		integer(2)			:: iU, iV, iW, iT

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check file exists
		inquire(file=sFileName, exist=lExist)
		if(.not.lExist) then
			iRetCode = 1
			return
		end if

		! Set type of ultrasonic anemometer
		if(present(iSonicType)) then
			iSonic = iSonicType
		else
			iSonic = SONIC_USONIC3
		end if

		! Check file name to be a valid WindRecorder, and obtain its time base
		sBaseName = baseName(sFileName, iOS)
		if(len_trim(sBaseName) /= 11) then
			iRetCode = 2
			return
		end if
		read(sBaseName, "(i4,2i2,1x,i2)", iostat=iErrCode) iYear, iMonth, iDay, iHour
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if
		open(iLUN, file=sFileName, status='old', action='read', iostat=iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 4
			close(iLUN)
			return
		end if
		tStamp = DateTime(iYear, iMonth, iDay, iHour, 0, 0.d0)
		rTimeBase = tStamp % toEpoch()

		! Count data and reserve workspace (note: no header, only meaningful data (and error packets)
		iNumData = 0
		do
			read(iLUN, "(a)", iostat=iErrCode) sBuffer
			if(iErrCode /= 0) exit
			if(sBuffer(1:1) /= 'E') iNumData = iNumData + 1
		end do
		if(iNumData <= 0) then
			iRetCode = 5
			close(iLUN)
			return
		end if
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % rvU)) deallocate(this % rvU)
		if(allocated(this % rvV)) deallocate(this % rvV)
		if(allocated(this % rvW)) deallocate(this % rvW)
		if(allocated(this % rvT)) deallocate(this % rvT)
		if(allocated(this % rvQ)) deallocate(this % rvQ)
		if(allocated(this % rvC)) deallocate(this % rvC)
		allocate(this % rvTimeStamp(iNumData))
		allocate(this % rvU(iNumData))
		allocate(this % rvV(iNumData))
		allocate(this % rvW(iNumData))
		allocate(this % rvT(iNumData))

		! Read actual data
		rewind(iLUN)
		read(iLUN, "(a)") sBuffer	! Skip header line
		select case(iSonic)
		case(SONIC_USONIC3)
			do i = 1, iNumData
				read(iLUN, "(1x,4(4x,i6))", iostat=iErrCode) iU, iV, iW, iT
				if(iErrCode == 0) then
					this % rvU(i) = iU / 100.
					this % rvV(i) = iV / 100.
					this % rvW(i) = iW / 100.
					this % rvT(i) = iT / 100.
				else
					this % rvU(i) = NaN
					this % rvV(i) = NaN
					this % rvW(i) = NaN
					this % rvT(i) = NaN
				end if
			end do
		case(SONIC_USA1)
			do i = 1, iNumData
				read(iLUN, "(1x,4(4x,i6))", iostat=iErrCode) iV, iU, iW, iT
				if(iErrCode == 0) then
					this % rvU(i) = iU / 100.
					this % rvV(i) = iV / 100.
					this % rvW(i) = iW / 100.
					this % rvT(i) = iT / 100.
				else
					this % rvU(i) = NaN
					this % rvV(i) = NaN
					this % rvW(i) = NaN
					this % rvT(i) = NaN
				end if
			end do
		end select
		close(iLUN)

		! Shift the time stamps read (representing second) by the base time,
		! obtaining full time stamps
		this % rvTimeStamp = rTimeBase + [((i-1)*3600.0/iNumData, i = 1, iNumData)]

		! Inform users all was OK
		this % isValid = .true.

	end function sd_ReadWindRecorder


	! Decode an uncompressed MFC V2 raw data file
	function sd_ReadMeteoFluxCoreUncompressed( &
		this, &
		iLUN, &
		sFileName, &
		iIndexQ, &
		rMultiplierQ, &
		rOffsetQ, &
		iIndexC, &
		rMultiplierC, &
		rOffsetC, &
		iDelayLag &
	) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(out)	:: this
		integer, intent(in)				:: iLUN
		character(len=*), intent(in)	:: sFileName
		integer, intent(in), optional	:: iIndexQ
		real, intent(in), optional		:: rMultiplierQ
		real, intent(in), optional		:: rOffsetQ
		integer, intent(in), optional	:: iIndexC
		real, intent(in), optional		:: rMultiplierC
		real, intent(in), optional		:: rOffsetC
		integer, intent(in), optional	:: iDelayLag
		integer							:: iRetCode

		! Locals
		integer				:: iErrCode
		type(DateTime)		:: tDt
		integer				:: iYear, iMonth, iDay, iHour
		real(8)				:: rBaseTime
		logical				:: isFile
		integer(2)			:: timeStamp, c1, c2, c3, c4
		integer				:: iNumQuadruples
		real, dimension(14)	:: dataLine
		logical				:: somePreviousData
		integer				:: iNumUnexpected
		integer				:: iData
		integer				:: iLen
		logical				:: lIsQ
		logical				:: lIsC

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check input file exists
		inquire(file=sFileName, exist=isFile)
		if(.not.isFile) then
			iRetCode = 1
			return
		end if
		lIsQ = present(iIndexQ) .and. present(rMultiplierQ) .and. present(rOffsetQ)
		lIsC = present(iIndexC) .and. present(rMultiplierC) .and. present(rOffsetC)
		if(lIsQ) then
			if(iIndexQ <= 4 .or. iIndexQ > 14) then
				iRetCode = 2
				return
			end if
		end if
		if(lIsC) then
			if(iIndexC <= 4 .or. iIndexC > 14) then
				iRetCode = 3
				return
			end if
		end if
		if(lIsQ .and. lIsC) then
			if(iIndexQ == iIndexC) then
				iRetCode = 4
				return
			end if
		end if
		if(present(iDelayLag)) then
			if(iDelayLag < 0) then
				iRetCode = 5
				return
			end if
		end if

		! Get time information from file name, and construct base time stamp from it
		iLen = len_trim(sFileName)
		if(iLen < 12) then
			iRetCode = 6
			return
		end if
		read(sFileName(iLen-11:), "(i4,2i2,1x,i2)") iYear, iMonth, iDay, iHour
		tDt = DateTime(iYear, iMonth, iDay, iHour, 0, 0.d0)
		rBaseTime = tDt % toEpoch()

		! Access data file and count how many sonic quadruples are contained within of it;
		! use this data piece to reserve workspace
		open(iLUN, file=sFileName, status='old', action='read', access='stream', iostat=iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 7
			return
		end if
		iNumQuadruples = 0
		do
			read(iLUN, iostat=iErrCode) timeStamp, c1, c2, c3, c4
			if(iErrCode /= 0) exit
			if(timeStamp / 5000 <= 0) iNumQuadruples = iNumQuadruples + 1
		end do
		if(iNumQuadruples <= 0) then
			iRetCode = 8
			return
		end if
		if(ALLOCATED(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(ALLOCATED(this % rvU))         deallocate(this % rvU)
		if(ALLOCATED(this % rvV))         deallocate(this % rvV)
		if(ALLOCATED(this % rvW))         deallocate(this % rvW)
		if(ALLOCATED(this % rvT))         deallocate(this % rvT)
		if(ALLOCATED(this % rvQ))         deallocate(this % rvQ)
		if(ALLOCATED(this % rvC))         deallocate(this % rvC)
		allocate(this % rvTimeStamp(iNumQuadruples))
		allocate(this % rvU(iNumQuadruples))
		allocate(this % rvV(iNumQuadruples))
		allocate(this % rvW(iNumQuadruples))
		allocate(this % rvT(iNumQuadruples))
		allocate(this % rvQ(iNumQuadruples))
		allocate(this % rvC(iNumQuadruples))
		this % rvTimeStamp = NaN_8
		this % rvU         = NaN
		this % rvV         = NaN
		this % rvW         = NaN
		this % rvT         = NaN
		this % rvQ         = NaN
		this % rvC         = NaN

		! Decode the data just counted in file
		rewind(iLUN)
		iData            = 0
		iNumUnexpected   = 0
		dataLine         = NaN
		somePreviousData = .false.
		do
			read(iLUN, iostat=iErrCode) timeStamp, c1, c2, c3, c4
			if(iErrCode /= 0) exit
			select case(timeStamp / 5000)
			case(0)	! Sonic quadruple

				! Save previous data line, if it exists
				if(somePreviousData) then
					iData                      = iData + 1
					this % rvTimeStamp(iData)  = mod(timeStamp, 5000) + rBaseTime
					this % rvU(iData)          = dataLine(1)
					this % rvV(iData)          = dataLine(2)
					this % rvW(iData)          = dataLine(3)
					this % rvT(iData)          = dataLine(4)
					if(lIsQ) this % rvQ(iData) = dataLine(iIndexQ) * rMultiplierQ + rOffsetQ
					if(lIsC) this % rvC(iData) = dataLine(iIndexC) * rMultiplierC + rOffsetC
					dataLine                   = NaN
				end if

				! Sonic quadruple
				dataLine(1) = c1 / 100.0
				dataLine(2) = c2 / 100.0
				dataLine(3) = c3 / 100.0
				dataLine(4) = c4 / 100.0

				! Notify a data line now exists
				somePreviousData = .true.

			case(1)	! Analog block 1

				dataLine(5) = c1
				dataLine(6) = c2
				dataLine(7) = c3
				dataLine(8) = c4

			case(2)	! Analog block 2

				dataLine( 9) = c1
				dataLine(10) = c2
				dataLine(11) = c3
				dataLine(12) = c4

			case(3)	! Counters

				dataLine(13) = c1
				dataLine(14) = c2

			case default	! Unexpected

				iNumUnexpected = iNumUnexpected + 1

			end select
		end do

		! Save last (pending) data and release file connection
		iData = iData + 1
		if(iData > iNumQuadruples) then
			close(iLUN)
			iRetCode = 9
			return
		end if
		this % rvTimeStamp(iData)  = MOD(timeStamp, 5000) + rBaseTime
		this % rvU(iData)          = dataLine(1)
		this % rvV(iData)          = dataLine(2)
		this % rvW(iData)          = dataLine(3)
		this % rvT(iData)          = dataLine(4)
		if(lIsQ) this % rvQ(iData) = dataLine(iIndexQ) * rMultiplierQ + rOffsetQ
		if(lIsC) this % rvC(iData) = dataLine(iIndexC) * rMultiplierC + rOffsetC
		close(iLUN)

		! Clean out H2O and CO2 vectors, whichever containing no valid data
		if(count(.valid. this % rvQ) <= 0) deallocate(this % rvQ)
		if(count(.valid. this % rvC) <= 0) deallocate(this % rvC)
		if(allocated(this % rvC) .and. .not.allocated(this % rvQ)) then
			iRetCode = 10
			return
		end if

		! Apply the specified delay to H2O and CO2
		if(present(iDelayLag)) then
			if(lIsQ) then
				do iData = 1, size(this % rvQ) - iDelayLag
					this % rvQ(iData) = this % rvQ(iData + iDelayLag)
				end do
				if(iDelayLag > 0) then
					this % rvQ(size(this % rvQ) - iDelayLag + 1:) = NaN
				end if
			end if
			if(lIsC) then
				do iData = 1, size(this % rvC) - iDelayLag
					this % rvC(iData) = this % rvC(iData + iDelayLag)
				end do
				if(iDelayLag > 0) then
					this % rvC(size(this % rvC) - iDelayLag + 1:) = NaN
				end if
			end if
		end if

	end function sd_ReadMeteoFluxCoreUncompressed


	function sd_WriteSonicLib(this, iLUN, sFileName) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(in)	:: this
		integer, intent(in)				:: iLUN
		character(len=*), intent(in)	:: sFileName
		integer							:: iRetCode

		! Locals
		integer			:: iErrCode
		logical			:: lIsQ
		logical			:: lAreBoth
		integer			:: i
		real(8)			:: rBaseTime
		type(DateTime)	:: tDt

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check run type
		if(allocated(this % rvQ)) then
			lIsQ = .true.
			if(allocated(this % rvC)) then
				lAreBoth = .true.
			else
				lAreBoth = .false.
			end if
		else
			lIsQ = .false.
		end if

		! Compute base time
		rBaseTime = minval(this % rvTimeStamp)
		iErrCode = tDt % fromEpoch(rBaseTime)
		if(iErrCode /= 0) then
			iRetCode = 1
			return
		end if
		rBaseTime = tDt % toEpoch(CLP_HOUR)

		! Perform actual write to SonicLib file
		open(iLUN, file=sFileName, status="unknown", action="write", iostat=iErrCode)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		if(.not.lIsQ) then
			write(iLUN, "('time.stamp, u, v, w, t')")
			do i = 1, size(this % rvTimeStamp)
				write(iLUN, "(f8.3,4(',',f6.2))") &
					this % rvTimeStamp(i) - rBaseTime, &
					this % rvU(i), &
					this % rvV(i), &
					this % rvW(i), &
					this % rvT(i)
			end do
		elseif(lIsQ .and..not.lAreBoth) then
			write(iLUN, "('time.stamp, u, v, w, t, q')")
			do i = 1, size(this % rvTimeStamp)
				write(iLUN, "(f8.3,4(',',f6.2),',',e15.7)") &
					this % rvTimeStamp(i) - rBaseTime, &
					this % rvU(i), &
					this % rvV(i), &
					this % rvW(i), &
					this % rvT(i), &
					this % rvQ(i)
			end do
		else
			write(iLUN, "('time.stamp, u, v, w, t, q, c')")
			do i = 1, size(this % rvTimeStamp)
				write(iLUN, "(f8.3,4(',',f6.2),2(',',e15.7))") &
					this % rvTimeStamp(i) - rBaseTime, &
					this % rvU(i), &
					this % rvV(i), &
					this % rvW(i), &
					this % rvT(i), &
					this % rvQ(i), &
					this % rvC(i)
			end do
		end if
		close(iLUN)

	end function sd_WriteSonicLib


	function sd_Size(this) result(iSize)

		! Routine arguments
		class(SonicData), intent(in)	:: this
		integer							:: iSize

		! Locals
		! --none--

		! Get the information desired
		if(this % isValid) then
			iSize = size(this % rvTimeStamp)
		else
			iSize = 0
		end if

	end function sd_Size


	function sd_Valid(this) result(iValid)

		! Routine arguments
		class(SonicData), intent(in)	:: this
		integer							:: iValid

		! Locals
		integer	:: i
		logical :: lValid
		logical :: lIsQ
		logical :: lIsC

		! Scan data set, and count all totally valid records (count includes invalid data
		! in H2O and CO2, if present)
		iValid = 0
		lIsQ = allocated(this % rvQ)
		lIsC = allocated(this % rvC)
		do i = 1, size(this % rvTimeStamp)
			lValid = &
				(.valid. this % rvTimeStamp(i)) .and. &
				(.valid. this % rvU(i)) .and. &
				(.valid. this % rvV(i)) .and. &
				(.valid. this % rvW(i)) .and. &
				(.valid. this % rvT(i))
			if(lIsQ) lValid = lValid .and. (.valid. this % rvQ(i))
			if(lIsC) lValid = lValid .and. (.valid. this % rvC(i))
			if(lValid) then
				iValid = iValid + 1
			end if
		end do

	end function sd_Valid


	function sd_IsWater(this) result(lIs)

		! Routine arguments
		class(SonicData), intent(in)	:: this
		logical							:: lIs

		! Locals
		! --none--

		! Get the information piece desired (notice explicit short-circuit evaluation is used,
		! mainly for clarity-of-intent
		lIs = allocated(this % rvQ)
		if(lIs) then
			lIs = lIs .and. size(this % rvQ) > 0
			if(lIs) then
				lIs = lIs .and. count(.valid. this % rvQ) > 0
			end if
		end if

	end function sd_IsWater


	function sd_IsCarbonDioxide(this) result(lIs)

		! Routine arguments
		class(SonicData), intent(in)	:: this
		logical							:: lIs

		! Locals
		logical	:: lIsQ

		! Get the information piece desired (notice explicit short-circuit evaluation is used,
		! mainly for clarity-of-intent
		lIsQ = allocated(this % rvQ)
		if(lIs) then
			lIsQ = lIsQ .and. size(this % rvQ) > 0
			if(lIs) then
				lIsQ = lIsQ .and. count(.valid. this % rvQ) > 0
			end if
		end if
		lIs = allocated(this % rvC)
		if(lIs) then
			lIs = lIs .and. size(this % rvC) > 0
			if(lIs) then
				lIs = lIs .and. count(.valid. this % rvC) > 0
			end if
		end if
		lIs = lIs .and. lIsQ	! Essential, to ensure CO2-related eddy covariance processing makes sense (it would not, if water is missing)

	end function sd_IsCarbonDioxide


	function sd_RemoveTrend(this, iAveragingTime, tTrend) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(inout)						:: this				! Current ultrasonic anemometer data set
		integer, intent(in)									:: iAveragingTime	! Averaging period (s, positive, proper divisor of 3600)
		type(TrendData), intent(out), optional				:: tTrend			! TrendData object to hold information about trend values, confidence limits, and more
		integer												:: iRetCode

		! Locals
		integer								:: iErrCode
		integer, dimension(:), allocatable	:: ivTimeIndex
		real(8), dimension(:), allocatable	:: rvAggregTimeStamp
		integer								:: i
		integer								:: n
		integer								:: iIndex
		integer								:: iMaxBlock
		integer								:: iNumBlocks
		logical								:: lIsQ
		logical								:: lIsC
		logical								:: lValid
		real(8)								:: rBaseTime
		integer, dimension(:), allocatable	:: ivNumData
		real(8), dimension(:), allocatable	:: rvSumX
		real(8), dimension(:), allocatable	:: rvSumXX
		real(8), dimension(:), allocatable	:: rvSumU
		real(8), dimension(:), allocatable	:: rvSumV
		real(8), dimension(:), allocatable	:: rvSumW
		real(8), dimension(:), allocatable	:: rvSumT
		real(8), dimension(:), allocatable	:: rvSumQ
		real(8), dimension(:), allocatable	:: rvSumC
		real(8), dimension(:), allocatable	:: rvSumUU
		real(8), dimension(:), allocatable	:: rvSumVV
		real(8), dimension(:), allocatable	:: rvSumWW
		real(8), dimension(:), allocatable	:: rvSumTT
		real(8), dimension(:), allocatable	:: rvSumQQ
		real(8), dimension(:), allocatable	:: rvSumCC
		real(8), dimension(:), allocatable	:: rvSumXU
		real(8), dimension(:), allocatable	:: rvSumXV
		real(8), dimension(:), allocatable	:: rvSumXW
		real(8), dimension(:), allocatable	:: rvSumXT
		real(8), dimension(:), allocatable	:: rvSumXQ
		real(8), dimension(:), allocatable	:: rvSumXC
		real(8), dimension(:), allocatable	:: rvEstU
		real(8), dimension(:), allocatable	:: rvEstV
		real(8), dimension(:), allocatable	:: rvEstW
		real(8), dimension(:), allocatable	:: rvEstT
		real(8), dimension(:), allocatable	:: rvEstQ
		real(8), dimension(:), allocatable	:: rvEstC
		real(8), dimension(:), allocatable	:: rvSumEstU
		real(8), dimension(:), allocatable	:: rvSumEstV
		real(8), dimension(:), allocatable	:: rvSumEstW
		real(8), dimension(:), allocatable	:: rvSumEstT
		real(8), dimension(:), allocatable	:: rvSumEstQ
		real(8), dimension(:), allocatable	:: rvSumEstC
		real(8), dimension(:), allocatable	:: rvAlphaU
		real(8), dimension(:), allocatable	:: rvAlphaV
		real(8), dimension(:), allocatable	:: rvAlphaW
		real(8), dimension(:), allocatable	:: rvAlphaT
		real(8), dimension(:), allocatable	:: rvAlphaQ
		real(8), dimension(:), allocatable	:: rvAlphaC
		real(8), dimension(:), allocatable	:: rvBetaU
		real(8), dimension(:), allocatable	:: rvBetaV
		real(8), dimension(:), allocatable	:: rvBetaW
		real(8), dimension(:), allocatable	:: rvBetaT
		real(8), dimension(:), allocatable	:: rvBetaQ
		real(8), dimension(:), allocatable	:: rvBetaC
		real(8)								:: rEpsFact

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be done
		if(this % valid() <= 0) then
			iRetCode = 1
			return
		end if
		if(iAveragingTime <= 0 .or. mod(3600, iAveragingTime) /= 0) then
			iRetCode = 2
			return
		end if
		iNumBlocks = 3600 / iAveragingTime
		n = size(this % rvTimeStamp)
		if(n <= 0) then
			iRetCode = 3
			return
		end if

		! Construct time-based index, and allocate workspace based on it
		iErrCode = timeLinearIndex(this % rvTimeStamp, iAveragingTime, ivTimeIndex, rvAggregTimeStamp)
		if(iErrCode /= 0) then
			iRetCode = 4
			return
		end if
		iMaxBlock = maxval(ivTimeIndex)
		if(iMaxBlock <= 0) then
			iRetCode = 5
			return
		end if

		! Reserve workspace
		allocate( &
			ivNumData(iNumBlocks), &
			rvSumX(iNumBlocks), rvSumXX(iNumBlocks), &
			rvSumU(iNumBlocks), rvSumV(iNumBlocks), rvSumW(iNumBlocks), rvSumT(iNumBlocks), &
			rvSumUU(iNumBlocks), rvSumVV(iNumBlocks), rvSumWW(iNumBlocks), rvSumTT(iNumBlocks), &
			rvSumXU(iNumBlocks), rvSumXV(iNumBlocks), rvSumXW(iNumBlocks), rvSumXT(iNumBlocks), &
			rvAlphaU(iNumBlocks), rvBetaU(iNumBlocks), rvAlphaV(iNumBlocks), rvBetaV(iNumBlocks), &
			rvAlphaW(iNumBlocks), rvBetaW(iNumBlocks), rvAlphaT(iNumBlocks), rvBetaT(iNumBlocks), &
			rvSumEstU(iNumBlocks), rvSumEstV(iNumBlocks), rvSumEstW(iNumBlocks), rvSumEstT(iNumBlocks), &
			rvEstU(n), rvEstV(n), rvEstW(n), rvEstT(n) &
		)
		lIsQ = allocated(this % rvQ)
		if(lIsQ) then
			allocate( &
				rvSumQ(iNumBlocks), rvSumQQ(iNumBlocks), &
				rvSumXQ(iNumBlocks), &
				rvAlphaQ(iNumBlocks), rvBetaQ(iNumBlocks), &
				rvSumEstQ(iNumBlocks), &
				rvEstQ(n) &
			)
		end if
		lIsC = allocated(this % rvC)
		if(lIsC) then
			allocate( &
				rvSumC(iNumBlocks), rvSumCC(iNumBlocks), &
				rvSumXC(iNumBlocks), &
				rvAlphaC(iNumBlocks), rvBetaC(iNumBlocks), &
				rvSumEstC(iNumBlocks), &
				rvEstC(n) &
			)
		end if

		! Pre-assign time stamps
		rBaseTime = real(floor(minval(this % rvTimeStamp, mask=.valid. this % rvTimeStamp) / iAveragingTime, kind=8) &
						* iAveragingTime, kind=8)

		! Accumulate sums
		ivNumData = 0
		rvSumX    = 0.d0
		rvSumXX   = 0.d0
		rvSumU    = 0.d0
		rvSumV    = 0.d0
		rvSumW    = 0.d0
		rvSumT    = 0.d0
		rvSumUU   = 0.d0
		rvSumVV   = 0.d0
		rvSumWW   = 0.d0
		rvSumTT   = 0.d0
		rvSumXU   = 0.d0
		rvSumXV   = 0.d0
		rvSumXW   = 0.d0
		rvSumXT   = 0.d0
		if(lIsQ) then
			rvSumQ  = 0.d0
			rvSumQQ = 0.d0
			rvSumXQ = 0.d0
		end if
		if(lIsC) then
			rvSumC  = 0.d0
			rvSumCC = 0.d0
			rvSumXC = 0.d0
		end if
		do i = 1, size(ivTimeIndex)
			if(ivTimeIndex(i) > 0) then
				iIndex = ivTimeIndex(i)
				lValid = &
					(.valid. this % rvTimeStamp(i)) .and. &
					(.valid. this % rvU(i)) .and. &
					(.valid. this % rvV(i)) .and. &
					(.valid. this % rvW(i)) .and. &
					(.valid. this % rvT(i))
				if(lIsQ) lValid = lValid .and. (.valid. this % rvQ(i))
				if(lIsC) lValid = lValid .and. (.valid. this % rvC(i))
				if(lValid) then
					! Update count
					ivNumData(iIndex) = ivNumData(iIndex) + 1
					! Update first order accumulators
					rvSumX(iIndex)  = rvSumX(iIndex) + this % rvTimeStamp(i)
					rvSumU(iIndex)  = rvSumU(iIndex) + this % rvU(i)
					rvSumV(iIndex)  = rvSumV(iIndex) + this % rvV(i)
					rvSumW(iIndex)  = rvSumW(iIndex) + this % rvW(i)
					rvSumT(iIndex)  = rvSumT(iIndex) + this % rvT(i)
					! Update second order accumulators
					rvSumXX(iIndex) = rvSumXX(iIndex) + this % rvTimeStamp(i)**2
					rvSumXU(iIndex) = rvSumXU(iIndex) + this % rvTimeStamp(i) * this % rvU(i)
					rvSumXV(iIndex) = rvSumXV(iIndex) + this % rvTimeStamp(i) * this % rvV(i)
					rvSumXW(iIndex) = rvSumXW(iIndex) + this % rvTimeStamp(i) * this % rvW(i)
					rvSumXT(iIndex) = rvSumXT(iIndex) + this % rvTimeStamp(i) * this % rvT(i)
					rvSumUU(iIndex) = rvSumUU(iIndex) + this % rvU(i) ** 2
					rvSumVV(iIndex) = rvSumVV(iIndex) + this % rvV(i) ** 2
					rvSumWW(iIndex) = rvSumWW(iIndex) + this % rvW(i) ** 2
					rvSumTT(iIndex) = rvSumTT(iIndex) + this % rvT(i) ** 2
					! Update scalar accumulators
					if(lIsQ) then
						rvSumQ(iIndex)  = rvSumQ(iIndex) + this % rvQ(i)
						rvSumXQ(iIndex) = rvSumXQ(iIndex) + this % rvTimeStamp(i) * this % rvQ(i)
						rvSumQQ(iIndex) = rvSumQQ(iIndex) + this % rvQ(i) ** 2
					end if
					if(lIsC) then
						rvSumC(iIndex)  = rvSumC(iIndex) + this % rvC(i)
						rvSumXC(iIndex) = rvSumXC(iIndex) + this % rvTimeStamp(i) * this % rvC(i)
						rvSumCC(iIndex) = rvSumCC(iIndex) + this % rvC(i) ** 2
					end if
				end if
			end if
		end do

		! Estimate trend coefficients
		do i = 1, iMaxBlock
			rvBetaU(i)  = (ivNumData(i)*rvSumXU(i) - rvSumX(i)*rvSumU(i)) / (ivNumData(i)*rvSumXX(i) - rvSumX(i)**2)
			rvAlphaU(i) = (rvSumU(i) - rvBetaU(i) * rvSumX(i)) / ivNumData(i)
			rvBetaV(i)  = (ivNumData(i)*rvSumXV(i) - rvSumX(i)*rvSumV(i)) / (ivNumData(i)*rvSumXX(i) - rvSumX(i)**2)
			rvAlphaV(i) = (rvSumV(i) - rvBetaV(i) * rvSumX(i)) / ivNumData(i)
			rvBetaW(i)  = (ivNumData(i)*rvSumXW(i) - rvSumX(i)*rvSumW(i)) / (ivNumData(i)*rvSumXX(i) - rvSumX(i)**2)
			rvAlphaW(i) = (rvSumW(i) - rvBetaW(i) * rvSumX(i)) / ivNumData(i)
			rvBetaT(i)  = (ivNumData(i)*rvSumXT(i) - rvSumX(i)*rvSumT(i)) / (ivNumData(i)*rvSumXX(i) - rvSumX(i)**2)
			rvAlphaT(i) = (rvSumT(i) - rvBetaT(i) * rvSumX(i)) / ivNumData(i)
			if(lIsQ) then
				rvBetaQ(i)  = (ivNumData(i)*rvSumXQ(i) - rvSumX(i)*rvSumQ(i)) / (ivNumData(i)*rvSumXX(i) - rvSumX(i)**2)
				rvAlphaQ(i) = (rvSumQ(i) - rvBetaQ(i) * rvSumX(i)) / ivNumData(i)
			end if
			if(lIsC) then
				rvBetaC(i)  = (ivNumData(i)*rvSumXC(i) - rvSumX(i)*rvSumC(i)) / (ivNumData(i)*rvSumXX(i) - rvSumX(i)**2)
				rvAlphaC(i) = (rvSumC(i) - rvBetaC(i) * rvSumX(i)) / ivNumData(i)
			end if
		end do

		! Estimate trend values and accumulate their sums
		rvSumEstU = 0.d0
		rvSumEstV = 0.d0
		rvSumEstW = 0.d0
		rvSumEstT = 0.d0
		if(lIsQ) rvSumEstQ = 0.d0
		if(lIsC) rvSumEstC = 0.d0
		do i = 1, size(ivTimeIndex)
			if(ivTimeIndex(i) > 0) then
				iIndex = ivTimeIndex(i)
				lValid = &
					(.valid. this % rvTimeStamp(i)) .and. &
					(.valid. this % rvU(i)) .and. &
					(.valid. this % rvV(i)) .and. &
					(.valid. this % rvW(i)) .and. &
					(.valid. this % rvT(i))
				if(lIsQ) lValid = lValid .and. (.valid. this % rvQ(i))
				if(lIsC) lValid = lValid .and. (.valid. this % rvC(i))
				if(lValid) then
					rvEstU(i) = rvAlphaU(iIndex) + rvBetaU(iIndex) * this % rvTimeStamp(i)
					rvEstV(i) = rvAlphaV(iIndex) + rvBetaV(iIndex) * this % rvTimeStamp(i)
					rvEstW(i) = rvAlphaW(iIndex) + rvBetaW(iIndex) * this % rvTimeStamp(i)
					rvEstT(i) = rvAlphaT(iIndex) + rvBetaT(iIndex) * this % rvTimeStamp(i)
					rvSumEstU(iIndex) = rvSumEstU(iIndex) + rvEstU(i)
					rvSumEstV(iIndex) = rvSumEstV(iIndex) + rvEstV(i)
					rvSumEstW(iIndex) = rvSumEstW(iIndex) + rvEstW(i)
					rvSumEstT(iIndex) = rvSumEstT(iIndex) + rvEstT(i)
					if(lIsQ) then
						rvEstQ(i) = rvAlphaQ(iIndex) + rvBetaQ(iIndex) * this % rvTimeStamp(i)
						rvSumEstQ(iIndex) = rvSumEstQ(iIndex) + rvEstQ(i)
					end if
					if(lIsC) then
						rvEstC(i) = rvAlphaC(iIndex) + rvBetaC(iIndex) * this % rvTimeStamp(i)
						rvSumEstC(iIndex) = rvSumEstC(iIndex) + rvEstC(i)
					end if
				else
					rvEstU(i) = NaN_8
					rvEstV(i) = NaN_8
					rvEstW(i) = NaN_8
					rvEstT(i) = NaN_8
					if(lIsQ) rvEstQ(i) = NaN_8
					if(lIsC) rvEstC(i) = NaN_8
				end if
			end if
		end do

		! Remove trend, preserving the mean
		do i = 1, size(ivTimeIndex)
			if(ivTimeIndex(i) > 0) then
				iIndex = ivTimeIndex(i)
				lValid = &
					(.valid. this % rvTimeStamp(i)) .and. &
					(.valid. this % rvU(i)) .and. &
					(.valid. this % rvV(i)) .and. &
					(.valid. this % rvW(i)) .and. &
					(.valid. this % rvT(i))
				if(lIsQ) lValid = lValid .and. (.valid. this % rvQ(i))
				if(lIsC) lValid = lValid .and. (.valid. this % rvC(i))
				if(lValid) then
					this % rvU(i) = this % rvU(i) - rvEstU(i) + rvSumEstU(iIndex) / ivNumData(iIndex)
					this % rvV(i) = this % rvV(i) - rvEstV(i) + rvSumEstV(iIndex) / ivNumData(iIndex)
					this % rvW(i) = this % rvW(i) - rvEstW(i) + rvSumEstW(iIndex) / ivNumData(iIndex)
					this % rvT(i) = this % rvT(i) - rvEstT(i) + rvSumEstT(iIndex) / ivNumData(iIndex)
					if(lIsQ) this % rvQ(i) = this % rvQ(i) - rvEstQ(i) + rvSumEstQ(iIndex) / ivNumData(iIndex)
					if(lIsC) this % rvC(i) = this % rvC(i) - rvEstC(i) + rvSumEstC(iIndex) / ivNumData(iIndex)
				end if
			end if
		end do

		! If required, fill the TrendData object with reporting and evaluation data about trend
		if(present(tTrend)) then
			iErrCode = tTrend % clean()
			if(iErrCode /= 0) then
				iRetCode = 6
				return
			end if
			iErrCode = tTrend % reserve(iMaxBlock, lIsQ, lIsC)
			if(iErrCode /= 0) then
				iRetCode = 6
				return
			end if
			do i = 1, iMaxBlock

				! Copy the values alredy computed
				tTrend % ivNumData(i) = ivNumData(i)
				tTrend % rvAlphaU(i)  = rvAlphaU(i)
				tTrend % rvAlphaV(i)  = rvAlphaV(i)
				tTrend % rvAlphaW(i)  = rvAlphaW(i)
				tTrend % rvAlphaT(i)  = rvAlphaT(i)
				tTrend % rvBetaU(i)   = rvBetaU(i)
				tTrend % rvBetaV(i)   = rvBetaV(i)
				tTrend % rvBetaW(i)   = rvBetaW(i)
				tTrend % rvBetaT(i)   = rvBetaT(i)
				if(lIsQ) then
					tTrend % rvAlphaQ(i) = rvAlphaQ(i)
					tTrend % rvBetaQ(i)  = rvBetaQ(i)
				end if
				if(lIsC) then
					tTrend % rvAlphaC(i) = rvAlphaC(i)
					tTrend % rvBetaC(i)  = rvBetaC(i)
				end if

				! Compute diagnostic values
				n = ivNumData(i)
				if(n > 2) then

					! Compute the error squared sigmas
					rEpsFact = 1.d0/(n * (n-2.d0))
					tTrend % rvS2epsU(i) = rEpsFact * ( &
						n * rvSumUU(i) - rvSumU(i)**2 - &
						rvBetaU(i)**2 * (n * rvSumXX(i) - rvSumX(i)**2) &
					)
					tTrend % rvS2epsV(i) = rEpsFact * ( &
						n * rvSumVV(i) - rvSumV(i)**2 - &
						rvBetaV(i)**2 * (n * rvSumXX(i) - rvSumX(i)**2) &
					)
					tTrend % rvS2epsW(i) = rEpsFact * ( &
						n * rvSumWW(i) - rvSumW(i)**2 - &
						rvBetaW(i)**2 * (n * rvSumXX(i) - rvSumX(i)**2) &
					)
					tTrend % rvS2epsT(i) = rEpsFact * ( &
						n * rvSumTT(i) - rvSumT(i)**2 - &
						rvBetaT(i)**2 * (n * rvSumXX(i) - rvSumX(i)**2) &
					)
					if(lIsQ) then
						tTrend % rvS2epsQ(i) = rEpsFact * ( &
							n * rvSumQQ(i) - rvSumQ(i)**2 - &
							rvBetaQ(i)**2 * (n * rvSumXX(i) - rvSumX(i)**2) &
						)
					end if
					if(lIsC) then
						tTrend % rvS2epsC(i) = rEpsFact * ( &
							n * rvSumCC(i) - rvSumC(i)**2 - &
							rvBetaC(i)**2 * (n * rvSumXX(i) - rvSumX(i)**2) &
						)
					end if

					! Compute slope squared sigmas
					tTrend % rvS2betaU(i) = n*tTrend % rvS2epsU(i) / (n*rvSumXX(i) - rvSumX(i)**2)
					tTrend % rvS2betaV(i) = n*tTrend % rvS2epsV(i) / (n*rvSumXX(i) - rvSumX(i)**2)
					tTrend % rvS2betaW(i) = n*tTrend % rvS2epsW(i) / (n*rvSumXX(i) - rvSumX(i)**2)
					tTrend % rvS2betaT(i) = n*tTrend % rvS2epsT(i) / (n*rvSumXX(i) - rvSumX(i)**2)
					if(lIsQ) then
						tTrend % rvS2betaQ(i) = n*tTrend % rvS2epsQ(i) / (n*rvSumXX(i) - rvSumX(i)**2)
					end if
					if(lIsC) then
						tTrend % rvS2betaC(i) = n*tTrend % rvS2epsC(i) / (n*rvSumXX(i) - rvSumX(i)**2)
					end if

					! Compute intercept squared sigmas
					tTrend % rvS2alphaU(i) = tTrend % rvS2betaU(i) * rvSumXX(i) / n
					tTrend % rvS2alphaV(i) = tTrend % rvS2betaV(i) * rvSumXX(i) / n
					tTrend % rvS2alphaW(i) = tTrend % rvS2betaW(i) * rvSumXX(i) / n
					tTrend % rvS2alphaT(i) = tTrend % rvS2betaT(i) * rvSumXX(i) / n
					if(lIsQ) then
						tTrend % rvS2alphaQ(i) = tTrend % rvS2betaQ(i) * rvSumXX(i) / n
					end if
					if(lIsC) then
						tTrend % rvS2alphaC(i) = tTrend % rvS2betaC(i) * rvSumXX(i) / n
					end if

				else

					tTrend % rvS2epsU(i) = NaN_8
					tTrend % rvS2epsV(i) = NaN_8
					tTrend % rvS2epsW(i) = NaN_8
					tTrend % rvS2epsT(i) = NaN_8

					tTrend % rvS2alphaU(i) = NaN_8
					tTrend % rvS2alphaV(i) = NaN_8
					tTrend % rvS2alphaW(i) = NaN_8
					tTrend % rvS2alphaT(i) = NaN_8

					tTrend % rvS2betaU(i) = NaN_8
					tTrend % rvS2betaV(i) = NaN_8
					tTrend % rvS2betaW(i) = NaN_8
					tTrend % rvS2betaT(i) = NaN_8

					if(lIsQ) then
						tTrend % rvS2epsQ(i)   = NaN_8
						tTrend % rvS2alphaQ(i) = NaN_8
						tTrend % rvS2betaQ(i)  = NaN_8
					end if

					if(lIsC) then
						tTrend % rvS2epsC(i)   = NaN_8
						tTrend % rvS2alphaC(i) = NaN_8
						tTrend % rvS2betaC(i)  = NaN_8
					end if

				end if
			end do
		end if

		! Leave
		deallocate( &
			ivNumData, &
			rvSumX, rvSumXX, rvSumU, rvSumV, rvSumW, rvSumT, rvSumUU, rvSumVV, rvSumWW, rvSumTT, &
			rvSumXU, rvSumXV, rvSumXW, rvSumXT, &
			rvAlphaU, rvBetaU, rvAlphaV, rvBetaV, rvAlphaW, rvBetaW, rvAlphaT, rvBetaT, &
			rvSumEstU, rvSumEstV, rvSumEstW, rvSumEstT, &
			rvEstU, rvEstV, rvEstW, rvEstT &
		)
		if(lIsQ) then
			deallocate( &
				rvSumQ, rvSumQQ, &
				rvSumXQ, &
				rvAlphaQ, rvBetaQ, &
				rvSumEstQ, &
				rvEstQ &
			)
		end if
		if(lIsC) then
			deallocate( &
				rvSumC, rvSumCC, &
				rvSumXC, &
				rvAlphaC, rvBetaC, &
				rvSumEstC, &
				rvEstC &
			)
		end if

	end function sd_RemoveTrend


	function sd_TreatSpikes(this, iAveragingTime, iMode, rNumStdDevIn, tSpikeCounts) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(inout)						:: this				! Current ultrasonic anemometer data set
		integer, intent(in)									:: iAveragingTime	! Averaging period (s, positive, proper divisor of 3600)
		integer, intent(in)									:: iMode			! Computing mode (SPK_REMOVE invalidate spikes; SPK_CLIP clips them to the prescribed number of standard deviations from average)
		real, intent(in), optional							:: rNumStdDevIn		! Number of standard deviations of distance to mean, beyond (below, if negative difference) past which data is considered a spike
		type(SpikeCounts), intent(out), optional			:: tSpikeCounts		! Counts of spikes
		integer												:: iRetCode

		! Locals
		integer								:: iErrCode
		real(8)								:: rNumStdDev
		integer, dimension(:), allocatable	:: ivTimeIndex
		real(8), dimension(:), allocatable	:: rvAggregTimeStamp
		integer								:: i
		integer								:: n
		logical								:: lIsQ
		logical								:: lIsC
		integer								:: iIndex
		integer								:: iMaxBlock
		integer								:: iNumBlocks
		real(8)								:: rBaseTime
		real(8)								:: rDelta
		integer, dimension(:), allocatable	:: ivNumData
		real(8), dimension(:), allocatable	:: rvSumU
		real(8), dimension(:), allocatable	:: rvSumV
		real(8), dimension(:), allocatable	:: rvSumW
		real(8), dimension(:), allocatable	:: rvSumT
		real(8), dimension(:), allocatable	:: rvSumQ
		real(8), dimension(:), allocatable	:: rvSumC
		real(8), dimension(:), allocatable	:: rvSumUU
		real(8), dimension(:), allocatable	:: rvSumVV
		real(8), dimension(:), allocatable	:: rvSumWW
		real(8), dimension(:), allocatable	:: rvSumTT
		real(8), dimension(:), allocatable	:: rvSumQQ
		real(8), dimension(:), allocatable	:: rvSumCC

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something is to be done
		if(this % valid() <= 0) then
			iRetCode = 1
			return
		end if
		if(iAveragingTime <= 0 .or. mod(3600, iAveragingTime) /= 0 .or. iMode < SPK_REMOVE .or. iMode > SPK_CLIP) then
			iRetCode = 2
			return
		end if
		iNumBlocks = 3600 / iAveragingTime
		n = size(this % rvTimeStamp)
		if(n <= 0) then
			iRetCode = 3
			return
		end if

		! Set default value(s)
		if(present(rNumStdDevIn)) then
			if(rNumStdDevIn /= 0.) then
				rNumStdDev = abs(rNumStdDevIn)
			else
				rNumStdDev = 3.d0
			end if
		else
			rNumStdDev = 3.d0
		end if

		! Construct time-based index, and allocate workspace based on it
		iErrCode = timeLinearIndex(this % rvTimeStamp, iAveragingTime, ivTimeIndex, rvAggregTimeStamp)
		if(iErrCode /= 0) then
			iRetCode = 4
			return
		end if
		iMaxBlock = maxval(ivTimeIndex)
		if(iMaxBlock <= 0) then
			iRetCode = 5
			return
		end if

		! Reserve workspace
		allocate( &
			ivNumData(iNumBlocks), &
			rvSumU(iNumBlocks), rvSumV(iNumBlocks), rvSumW(iNumBlocks), rvSumT(iNumBlocks), &
			rvSumUU(iNumBlocks), rvSumVV(iNumBlocks), rvSumWW(iNumBlocks), rvSumTT(iNumBlocks) &
		)
		lIsQ = allocated(this % rvQ)
		if(lIsQ) then
			allocate( &
				rvSumQ(iNumBlocks), rvSumQQ(iNumBlocks) &
			)
		end if
		lIsC = allocated(this % rvC)
		if(lIsC) then
			allocate( &
				rvSumC(iNumBlocks), rvSumCC(iNumBlocks) &
			)
		end if
		if(present(tSpikeCounts)) then
			iErrCode = tSpikeCounts % clean()
			if(iErrCode /= 0) then
				iRetCode = 6
				return
			end if
			iErrCode = tSpikeCounts % reserve(iNumBlocks)
			if(iErrCode /= 0) then
				iErrCode = tSpikeCounts % clean()
				iRetCode = 7
				return
			end if
		end if

		! Pre-assign time stamps
		rBaseTime = real(floor(minval(this % rvTimeStamp, mask=.valid. this % rvTimeStamp) / iAveragingTime, kind=8) &
						* iAveragingTime, kind=8)

		! Accumulate sums
		ivNumData = 0
		rvSumU    = 0.d0
		rvSumV    = 0.d0
		rvSumW    = 0.d0
		rvSumT    = 0.d0
		rvSumUU   = 0.d0
		rvSumVV   = 0.d0
		rvSumWW   = 0.d0
		rvSumTT   = 0.d0
		do i = 1, size(ivTimeIndex)
			if(ivTimeIndex(i) > 0) then
				iIndex = ivTimeIndex(i)
				if( &
					(.valid. this % rvTimeStamp(i)) .and. &
					(.valid. this % rvU(i)) .and. &
					(.valid. this % rvV(i)) .and. &
					(.valid. this % rvW(i)) .and. &
					(.valid. this % rvT(i)) &
				) then
					! Update count
					ivNumData(iIndex) = ivNumData(iIndex) + 1
					! Update first order accumulators
					rvSumU(iIndex)  = rvSumU(iIndex) + this % rvU(i)
					rvSumV(iIndex)  = rvSumV(iIndex) + this % rvV(i)
					rvSumW(iIndex)  = rvSumW(iIndex) + this % rvW(i)
					rvSumT(iIndex)  = rvSumT(iIndex) + this % rvT(i)
					! Update second order accumulators
					rvSumUU(iIndex) = rvSumUU(iIndex) + this % rvU(i) ** 2
					rvSumVV(iIndex) = rvSumVV(iIndex) + this % rvV(i) ** 2
					rvSumWW(iIndex) = rvSumWW(iIndex) + this % rvW(i) ** 2
					rvSumTT(iIndex) = rvSumTT(iIndex) + this % rvT(i) ** 2
				end if
			end if
		end do

		! Convert sums to mean and variance
		do i = 1, iMaxBlock
			if(ivNumData(i) > 0) then
				rvSumU(i)  = rvSumU(i) / ivNumData(i)
				rvSumV(i)  = rvSumV(i) / ivNumData(i)
				rvSumW(i)  = rvSumW(i) / ivNumData(i)
				rvSumT(i)  = rvSumT(i) / ivNumData(i)
				rvSumUU(i) = sqrt(rvSumUU(i) / ivNumData(i) - rvSumU(i)**2)
				rvSumVV(i) = sqrt(rvSumVV(i) / ivNumData(i) - rvSumV(i)**2)
				rvSumWW(i) = sqrt(rvSumWW(i) / ivNumData(i) - rvSumW(i)**2)
				rvSumTT(i) = sqrt(rvSumTT(i) / ivNumData(i) - rvSumT(i)**2)
			else
				rvSumU(i)  = NaN_8
				rvSumV(i)  = NaN_8
				rvSumW(i)  = NaN_8
				rvSumT(i)  = NaN_8
				rvSumUU(i) = NaN_8
				rvSumVV(i) = NaN_8
				rvSumWW(i) = NaN_8
				rvSumTT(i) = NaN_8
			end if
		end do

		! Iterate over all data, and decide whether they are spikes or not;
		! then, act accordingly
		do i = 1, size(ivTimeIndex)
			if(ivTimeIndex(i) > 0) then
				iIndex = ivTimeIndex(i)
				if( &
					(.valid. this % rvTimeStamp(i)) .and. &
					(.valid. this % rvU(i)) .and. &
					(.valid. this % rvV(i)) .and. &
					(.valid. this % rvW(i)) .and. &
					(.valid. this % rvT(i)) &
				) then
					! Check values correspond to spikes, and act depending on the
					! method selected
					rDelta = (this % rvU(i) - rvSumU(iIndex)) / rvSumUU(iIndex)
					if(rDelta > rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvU(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvU(i) = rvSumU(iIndex) + rvSumUU(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesU(iIndex) = tSpikeCounts % ivNumSpikesU(iIndex) + 1
					elseif(rDelta < -rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvU(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvU(i) = rvSumU(iIndex) - rvSumUU(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesU(iIndex) = tSpikeCounts % ivNumSpikesU(iIndex) + 1
					end if
					if(rDelta > rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvV(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvV(i) = rvSumV(iIndex) + rvSumVV(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesV(iIndex) = tSpikeCounts % ivNumSpikesV(iIndex) + 1
					elseif(rDelta < -rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvW(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvV(i) = rvSumV(iIndex) - rvSumVV(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesV(iIndex) = tSpikeCounts % ivNumSpikesV(iIndex) + 1
					end if
					if(rDelta > rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvW(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvW(i) = rvSumW(iIndex) + rvSumWW(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesW(iIndex) = tSpikeCounts % ivNumSpikesW(iIndex) + 1
					elseif(rDelta < -rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvW(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvW(i) = rvSumW(iIndex) - rvSumWW(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesW(iIndex) = tSpikeCounts % ivNumSpikesW(iIndex) + 1
					end if
					if(rDelta > rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvT(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvT(i) = rvSumT(iIndex) + rvSumTT(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesT(iIndex) = tSpikeCounts % ivNumSpikesT(iIndex) + 1
					elseif(rDelta < -rNumStdDev) then
						if(iMode == SPK_REMOVE) then
							this % rvT(i) = NaN
						elseif(iMode == SPK_CLIP) then
							this % rvT(i) = rvSumT(iIndex) - rvSumTT(iIndex) * rNumStdDev
						end if
						if(present(tSpikeCounts)) tSpikeCounts % ivNumSpikesT(iIndex) = tSpikeCounts % ivNumSpikesT(iIndex) + 1
					end if
				end if
			end if
		end do

		! Leave
		deallocate( &
			ivNumData, &
			rvSumU, rvSumV, rvSumW, rvSumT, rvSumUU, rvSumVV, rvSumWW, rvSumTT &
		)

	end function sd_TreatSpikes


	function sd_Averages(this, iAveragingTime, tEc) result(iRetCode)

		! Routine arguments
		class(SonicData), intent(in)						:: this				! Current ultrasonic anemometer data set
		integer, intent(in)									:: iAveragingTime	! Averaging period (s, positive, proper divisor of 3600)
		type(EddyCovData), intent(out)						:: tEc				! Eddy covariance data, input fields only are output
		integer												:: iRetCode

		! Locals
		integer								:: iErrCode
		integer, dimension(:), allocatable	:: ivTimeIndex
		real(8), dimension(:), allocatable	:: rvAggregTimeStamp
		integer								:: i
		integer								:: iIndex
		integer								:: iMaxBlock
		integer								:: iNumBlocks
		real(8)								:: rBaseTime
		logical								:: lIsQ
		logical								:: lIsC

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Pre-clean the EddyCovData object, so that we're sure anything bad happens results in a
		! defined state
		iErrCode = tEc % clean()
		if(iErrCode /= 0) then
			iRetCode = 1
			return
		end if

		! Check something is to be done
		if(this % valid() <= 0) then
			iRetCode = 2
			return
		end if
		if(iAveragingTime <= 0 .or. mod(3600, iAveragingTime) /= 0) then
			iRetCode = 3
			return
		end if
		iNumBlocks = 3600 / iAveragingTime

		! Construct time-based index, and allocate workspace based on it
		iErrCode = timeLinearIndex(this % rvTimeStamp, iAveragingTime, ivTimeIndex, rvAggregTimeStamp)
		if(iErrCode /= 0) then
			iRetCode = 4
			return
		end if
		iMaxBlock = maxval(ivTimeIndex)
		if(iMaxBlock <= 0 .or. iMaxBlock > iNumBlocks) then
			iRetCode = 5
			return
		end if
		if(tEc % reserve(iNumBlocks) /= 0) then
			iRetCode = 6
			return
		end if

		! Pre-assign time stamps
		rBaseTime = real(floor(minval(this % rvTimeStamp, mask=.valid. this % rvTimeStamp) / iAveragingTime, kind=8) &
						* iAveragingTime, kind=8)
		tEc % rvTimeStamp = [(rBaseTime + (i-1)*real(iAveragingTime, kind=8), i = 1, iNumBlocks)]

		! Check whether water and carbon dioxide processing is to be made
		lIsQ = allocated(tEc % rvQ)
		lIsC = allocated(tEc % rvQ) .and. allocated(tEc % rvC)

		! Compute the desired statistics
		! -1- Phase one: Accumulate
		tEc % ivNumData = 0
		tEc % rmVel     = 0.d0
		tEc % rvT       = 0.d0
		tEc % raCovVel  = 0.d0
		tEc % rmCovT    = 0.d0
		tEc % rvVarT    = 0.d0
		tEc % isPrimed  = .true.
		if(lIsQ) then
			tEc % rvQ       = 0.d0
			tEc % rmCovQ    = 0.d0
			tEc % rvVarQ    = 0.d0
		end if
		if(lIsC) then
			tEc % rvC       = 0.d0
			tEc % rmCovC    = 0.d0
			tEc % rvVarC    = 0.d0
		end if
		do i = 1, size(ivTimeIndex)
			if(ivTimeIndex(i) > 0) then
				iIndex = ivTimeIndex(i)
				if( &
					(.valid. this % rvTimeStamp(i)) .and. &
					(.valid. this % rvU(i)) .and. &
					(.valid. this % rvV(i)) .and. &
					(.valid. this % rvW(i)) .and. &
					(.valid. this % rvT(i)) &
				) then
					! Update count
					tEc % ivNumData(iIndex) = tEc % ivNumData(iIndex) + 1
					! Update first order accumulators
					tEc % rmVel(iIndex, 1)       = tEc % rmVel(iIndex, 1)       + real(this % rvU(i), kind=8)
					tEc % rmVel(iIndex, 2)       = tEc % rmVel(iIndex, 2)       + real(this % rvV(i), kind=8)
					tEc % rmVel(iIndex, 3)       = tEc % rmVel(iIndex, 3)       + real(this % rvW(i), kind=8)
					tEc % rvT(iIndex)            = tEc % rvT(iIndex)            + real(this % rvT(i), kind=8)
					! Update second order accumulators
					tEc % raCovVel(iIndex, 1, 1) = tEc % raCovVel(iIndex, 1, 1) + real(this % rvU(i), kind=8) ** 2
					tEc % raCovVel(iIndex, 2, 2) = tEc % raCovVel(iIndex, 2, 2) + real(this % rvV(i), kind=8) ** 2
					tEc % raCovVel(iIndex, 3, 3) = tEc % raCovVel(iIndex, 3, 3) + real(this % rvW(i), kind=8) ** 2
					tEc % rvVarT(iIndex)         = tEc % rvVarT(iIndex)         + real(this % rvT(i), kind=8) ** 2
					tEc % raCovVel(iIndex, 1, 2) = tEc % raCovVel(iIndex, 1, 2) + &
						real(this % rvU(i), kind=8) * real(this % rvV(i), kind=8)
					tEc % raCovVel(iIndex, 1, 3) = tEc % raCovVel(iIndex, 1, 3) + &
						real(this % rvU(i), kind=8) * real(this % rvW(i), kind=8)
					tEc % raCovVel(iIndex, 2, 3) = tEc % raCovVel(iIndex, 2, 3) + &
						real(this % rvV(i), kind=8) * real(this % rvW(i), kind=8)
					tEc % rmCovT(iIndex, 1)      = tEc % rmCovT(iIndex, 1)      + &
						real(this % rvU(i), kind=8) * real(this % rvT(i), kind=8)
					tEc % rmCovT(iIndex, 2)      = tEc % rmCovT(iIndex, 2)      + &
						real(this % rvV(i), kind=8) * real(this % rvT(i), kind=8)
					tEc % rmCovT(iIndex, 3)      = tEc % rmCovT(iIndex, 3)      + &
						real(this % rvW(i), kind=8) * real(this % rvT(i), kind=8)
					if(lIsQ) then
						tEc % rvQ(iIndex)            = tEc % rvQ(iIndex)            + real(this % rvQ(i), kind=8)
						tEc % rvVarQ(iIndex)         = tEc % rvVarQ(iIndex)         + real(this % rvQ(i), kind=8) ** 2
						tEc % rmCovQ(iIndex, 1)      = tEc % rmCovQ(iIndex, 1)      + &
							real(this % rvU(i), kind=8) * real(this % rvQ(i), kind=8)
						tEc % rmCovQ(iIndex, 2)      = tEc % rmCovQ(iIndex, 2)      + &
							real(this % rvV(i), kind=8) * real(this % rvQ(i), kind=8)
						tEc % rmCovQ(iIndex, 3)      = tEc % rmCovQ(iIndex, 3)      + &
							real(this % rvW(i), kind=8) * real(this % rvQ(i), kind=8)
					end if
					if(lIsC) then
						tEc % rvC(iIndex)            = tEc % rvC(iIndex)            + real(this % rvC(i), kind=8)
						tEc % rvVarC(iIndex)         = tEc % rvVarC(iIndex)         + real(this % rvC(i), kind=8) ** 2
						tEc % rmCovC(iIndex, 1)      = tEc % rmCovC(iIndex, 1)      + &
							real(this % rvU(i), kind=8) * real(this % rvC(i), kind=8)
						tEc % rmCovC(iIndex, 2)      = tEc % rmCovC(iIndex, 2)      + &
							real(this % rvV(i), kind=8) * real(this % rvC(i), kind=8)
						tEc % rmCovC(iIndex, 3)      = tEc % rmCovC(iIndex, 3)      + &
							real(this % rvW(i), kind=8) * real(this % rvC(i), kind=8)
					end if
				end if
			end if
		end do
		! -1- Phase two: Render
		do i = 1, iMaxBlock
			if(tEc % ivNumData(i) > 0) then
				tEc % rmVel(i,:)      = tEc % rmVel(i,:) / tEc % ivNumData(i)
				tEc % rvT(i)          = tEc % rvT(i) / tEc % ivNumData(i)
				tEc % raCovVel(i,1,1) = tEc % raCovVel(i,1,1) / tEc % ivNumData(i) - tEc % rmVel(i, 1) ** 2
				tEc % raCovVel(i,2,2) = tEc % raCovVel(i,2,2) / tEc % ivNumData(i) - tEc % rmVel(i, 2) ** 2
				tEc % raCovVel(i,3,3) = tEc % raCovVel(i,3,3) / tEc % ivNumData(i) - tEc % rmVel(i, 3) ** 2
				tEc % rvVarT(i)       = tEc % rvVarT(i) / tEc % ivNumData(i) - tEc % rvT(i) ** 2
				tEc % raCovVel(i,1,2) = tEc % raCovVel(i,1,2) / tEc % ivNumData(i) - tEc % rmVel(i, 1) * tEc % rmVel(i, 2)
				tEc % raCovVel(i,1,3) = tEc % raCovVel(i,1,3) / tEc % ivNumData(i) - tEc % rmVel(i, 1) * tEc % rmVel(i, 3)
				tEc % raCovVel(i,2,3) = tEc % raCovVel(i,2,3) / tEc % ivNumData(i) - tEc % rmVel(i, 2) * tEc % rmVel(i, 3)
				tEc % raCovVel(i,2,1) = tEc % raCovVel(i,1,2)
				tEc % raCovVel(i,3,1) = tEc % raCovVel(i,1,3)
				tEc % raCovVel(i,3,2) = tEc % raCovVel(i,2,3)
				tEc % rmCovT(i,1)     = tEc % rmCovT(i,1) / tEc % ivNumData(i) - tEc % rmVel(i, 1) * tEc % rvT(i)
				tEc % rmCovT(i,2)     = tEc % rmCovT(i,2) / tEc % ivNumData(i) - tEc % rmVel(i, 2) * tEc % rvT(i)
				tEc % rmCovT(i,3)     = tEc % rmCovT(i,3) / tEc % ivNumData(i) - tEc % rmVel(i, 3) * tEc % rvT(i)
				if(lIsQ) then
					tEc % rvQ(i)          = tEc % rvQ(i) / tEc % ivNumData(i)
					tEc % rvVarQ(i)       = tEc % rvVarQ(i) / tEc % ivNumData(i) - tEc % rvQ(i) ** 2
					tEc % rmCovQ(i,1)     = tEc % rmCovQ(i,1) / tEc % ivNumData(i) - tEc % rmVel(i, 1) * tEc % rvQ(i)
					tEc % rmCovQ(i,2)     = tEc % rmCovQ(i,2) / tEc % ivNumData(i) - tEc % rmVel(i, 2) * tEc % rvQ(i)
					tEc % rmCovQ(i,3)     = tEc % rmCovQ(i,3) / tEc % ivNumData(i) - tEc % rmVel(i, 3) * tEc % rvQ(i)
				end if
				if(lIsC) then
					tEc % rvC(i)          = tEc % rvC(i) / tEc % ivNumData(i)
					tEc % rvVarC(i)       = tEc % rvVarC(i) / tEc % ivNumData(i) - tEc % rvC(i) ** 2
					tEc % rmCovC(i,1)     = tEc % rmCovC(i,1) / tEc % ivNumData(i) - tEc % rmVel(i, 1) * tEc % rvC(i)
					tEc % rmCovC(i,2)     = tEc % rmCovC(i,2) / tEc % ivNumData(i) - tEc % rmVel(i, 2) * tEc % rvC(i)
					tEc % rmCovC(i,3)     = tEc % rmCovC(i,3) / tEc % ivNumData(i) - tEc % rmVel(i, 3) * tEc % rvC(i)
				end if
			else
				tEc % rmVel(i,:)      = NaN_8
				tEc % rvT(i)          = NaN_8
				tEc % raCovVel(i,:,:) = NaN_8
				tEc % rvVarT(i)       = NaN_8
				tEc % rmCovT(i,:)     = NaN_8
				if(lIsQ) then
					tEc % rvQ(i)          = NaN_8
					tEc % rvVarQ(i)       = NaN_8
					tEc % rmCovQ(i,:)     = NaN_8
				end if
				if(lIsC) then
					tEc % rvC(i)          = NaN_8
					tEc % rvVarC(i)       = NaN_8
					tEc % rmCovC(i,:)     = NaN_8
				end if
			end if
		end do

		! Perfection status
		tEc % averagingTime = iAveragingTime

	end function sd_Averages


	function td_Clean(this) result(iRetCode)

		! Routine arguments
		class(TrendData), intent(inout)	:: this
		integer							:: iRetCode

		! Locals
		! --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Remove any allocated vector
		if(allocated(this % ivNumData))  deallocate(this % ivNumData)
		if(allocated(this % rvAlphaU))   deallocate(this % rvAlphaU)
		if(allocated(this % rvAlphaV))   deallocate(this % rvAlphaV)
		if(allocated(this % rvAlphaW))   deallocate(this % rvAlphaW)
		if(allocated(this % rvAlphaT))   deallocate(this % rvAlphaT)
		if(allocated(this % rvAlphaQ))   deallocate(this % rvAlphaQ)
		if(allocated(this % rvAlphaC))   deallocate(this % rvAlphaC)
		if(allocated(this % rvBetaU))    deallocate(this % rvBetaU)
		if(allocated(this % rvBetaV))    deallocate(this % rvBetaV)
		if(allocated(this % rvBetaW))    deallocate(this % rvBetaW)
		if(allocated(this % rvBetaT))    deallocate(this % rvBetaT)
		if(allocated(this % rvBetaQ))    deallocate(this % rvBetaQ)
		if(allocated(this % rvBetaC))    deallocate(this % rvBetaC)
		if(allocated(this % rvS2epsU))   deallocate(this % rvS2epsU)
		if(allocated(this % rvS2epsV))   deallocate(this % rvS2epsV)
		if(allocated(this % rvS2epsW))   deallocate(this % rvS2epsW)
		if(allocated(this % rvS2epsT))   deallocate(this % rvS2epsT)
		if(allocated(this % rvS2epsQ))   deallocate(this % rvS2epsQ)
		if(allocated(this % rvS2epsC))   deallocate(this % rvS2epsC)
		if(allocated(this % rvS2alphaU)) deallocate(this % rvS2alphaU)
		if(allocated(this % rvS2alphaV)) deallocate(this % rvS2alphaV)
		if(allocated(this % rvS2alphaW)) deallocate(this % rvS2alphaW)
		if(allocated(this % rvS2alphaT)) deallocate(this % rvS2alphaT)
		if(allocated(this % rvS2alphaQ)) deallocate(this % rvS2alphaQ)
		if(allocated(this % rvS2alphaC)) deallocate(this % rvS2alphaC)
		if(allocated(this % rvS2betaU))  deallocate(this % rvS2betaU)
		if(allocated(this % rvS2betaV))  deallocate(this % rvS2betaV)
		if(allocated(this % rvS2betaW))  deallocate(this % rvS2betaW)
		if(allocated(this % rvS2betaT))  deallocate(this % rvS2betaT)
		if(allocated(this % rvS2betaQ))  deallocate(this % rvS2betaQ)
		if(allocated(this % rvS2betaC))  deallocate(this % rvS2betaC)

	end function td_Clean


	function td_Allocate(this, iNumData, lAlsoQ, lAlsoC) result(iRetCode)

		! Routine arguments
		class(TrendData), intent(inout)	:: this
		integer, intent(in)				:: iNumData
		logical, intent(in), optional	:: lAlsoQ
		logical, intent(in), optional	:: lAlsoC
		integer							:: iRetCode

		! Locals
		! --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Remove any allocated vector
		allocate(this % ivNumData(iNumData))
		allocate(this % rvAlphaU(iNumData))
		allocate(this % rvAlphaV(iNumData))
		allocate(this % rvAlphaW(iNumData))
		allocate(this % rvAlphaT(iNumData))
		if(present(lAlsoQ)) then
			if(lAlsoQ) allocate(this % rvAlphaQ(iNumData))
		end if
		if(present(lAlsoC)) then
			if(lAlsoC) allocate(this % rvAlphaC(iNumData))
		end if
		allocate(this % rvBetaU(iNumData))
		allocate(this % rvBetaV(iNumData))
		allocate(this % rvBetaW(iNumData))
		allocate(this % rvBetaT(iNumData))
		if(present(lAlsoQ)) then
			if(lAlsoQ) allocate(this % rvBetaQ(iNumData))
		end if
		if(present(lAlsoC)) then
			if(lAlsoC) allocate(this % rvBetaC(iNumData))
		end if
		allocate(this % rvS2epsU(iNumData))
		allocate(this % rvS2epsV(iNumData))
		allocate(this % rvS2epsW(iNumData))
		allocate(this % rvS2epsT(iNumData))
		if(present(lAlsoQ)) then
			if(lAlsoQ) allocate(this % rvS2epsQ(iNumData))
		end if
		if(present(lAlsoC)) then
			if(lAlsoC) allocate(this % rvS2epsC(iNumData))
		end if
		allocate(this % rvS2alphaU(iNumData))
		allocate(this % rvS2alphaV(iNumData))
		allocate(this % rvS2alphaW(iNumData))
		allocate(this % rvS2alphaT(iNumData))
		if(present(lAlsoQ)) then
			if(lAlsoQ) allocate(this % rvS2alphaQ(iNumData))
		end if
		if(present(lAlsoC)) then
			if(lAlsoC) allocate(this % rvS2alphaC(iNumData))
		end if
		allocate(this % rvS2betaU(iNumData))
		allocate(this % rvS2betaV(iNumData))
		allocate(this % rvS2betaW(iNumData))
		allocate(this % rvS2betaT(iNumData))
		if(present(lAlsoQ)) then
			if(lAlsoQ) allocate(this % rvS2betaQ(iNumData))
		end if
		if(present(lAlsoC)) then
			if(lAlsoC) allocate(this % rvS2betaC(iNumData))
		end if

	end function td_Allocate


	function sc_Clean(this) result(iRetCode)

		! Routine arguments
		class(SpikeCounts), intent(inout)	:: this
		integer								:: iRetCode

		! Locals
		! --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Remove any allocated vector
		if(allocated(this % ivNumSpikesU))  deallocate(this % ivNumSpikesU)
		if(allocated(this % ivNumSpikesV))  deallocate(this % ivNumSpikesV)
		if(allocated(this % ivNumSpikesW))  deallocate(this % ivNumSpikesW)
		if(allocated(this % ivNumSpikesT))  deallocate(this % ivNumSpikesT)
		if(allocated(this % ivNumSpikesQ))  deallocate(this % ivNumSpikesQ)
		if(allocated(this % ivNumSpikesC))  deallocate(this % ivNumSpikesC)

	end function sc_Clean


	function sc_Allocate(this, iNumData, lAlsoQ, lAlsoC) result(iRetCode)

		! Routine arguments
		class(SpikeCounts), intent(inout)	:: this
		integer, intent(in)					:: iNumData
		logical, intent(in), optional		:: lAlsoQ
		logical, intent(in), optional		:: lAlsoC
		integer								:: iRetCode

		! Locals
		! --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Remove any allocated vector
		allocate(this % ivNumSpikesU(iNumData))
		allocate(this % ivNumSpikesV(iNumData))
		allocate(this % ivNumSpikesW(iNumData))
		allocate(this % ivNumSpikesT(iNumData))

		! Initialize to zero
		this % ivNumSpikesU = 0
		this % ivNumSpikesV = 0
		this % ivNumSpikesW = 0
		this % ivNumSpikesT = 0

		! H2O case
		if(lAlsoQ) then
			allocate(this % ivNumSpikesQ(iNumData))
			this % ivNumSpikesQ = 0
		end if
		if(lAlsoC) then
			allocate(this % ivNumSpikesC(iNumData))
			this % ivNumSpikesC = 0
		end if

	end function sc_Allocate


	function ec_Clean(this) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(inout)	:: this
		integer								:: iRetCode

		! Locals
		! --none--

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Set completion indicators to .false.
		this % isPrimed = .false.
		this % isFilled = .false.

		! Clean out the input part
		if(allocated(this % rvTimeStamp)) deallocate(this % rvTimeStamp)
		if(allocated(this % ivNumData))   deallocate(this % ivNumData)
		if(allocated(this % rmVel))       deallocate(this % rmVel)
		if(allocated(this % rvT))         deallocate(this % rvT)
		if(allocated(this % rvQ))         deallocate(this % rvQ)
		if(allocated(this % rvC))         deallocate(this % rvC)
		if(allocated(this % raCovVel))    deallocate(this % raCovVel)
		if(allocated(this % rmCovT))      deallocate(this % rmCovT)
		if(allocated(this % rvVarT))      deallocate(this % rvVarT)
		if(allocated(this % rmCovQ))      deallocate(this % rmCovQ)
		if(allocated(this % rvVarQ))      deallocate(this % rvVarQ)
		if(allocated(this % rmCovC))      deallocate(this % rmCovC)
		if(allocated(this % rvVarC))      deallocate(this % rvVarC)

		! Clean outputs
		if(allocated(this % rvTheta))     deallocate(this % rvTheta)
		if(allocated(this % rvPhi))       deallocate(this % rvPhi)
		if(allocated(this % rvPsi))       deallocate(this % rvPsi)
		if(allocated(this % rmRotVel))    deallocate(this % rmRotVel)
		if(allocated(this % raRotCovVel)) deallocate(this % raRotCovVel)
		if(allocated(this % rmRotCovT))   deallocate(this % rmRotCovT)
		if(allocated(this % rmRotCovQ))   deallocate(this % rmRotCovQ)
		if(allocated(this % rmRotCovC))   deallocate(this % rmRotCovC)
		if(allocated(this % rvUstar))     deallocate(this % rvUstar)
		if(allocated(this % rvUstar_3))   deallocate(this % rvUstar_3)
		if(allocated(this % rvH0))        deallocate(this % rvH0)
		if(allocated(this % rvHe))        deallocate(this % rvHe)
		if(allocated(this % rvFqMolar))   deallocate(this % rvFqMolar)
		if(allocated(this % rvFqMass))    deallocate(this % rvFqMass)
		if(allocated(this % rvFcMolar))   deallocate(this % rvFcMolar)
		if(allocated(this % rvFcMass))    deallocate(this % rvFcMass)

	end function ec_Clean


	function ec_Allocate(this, iNumData) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(inout)	:: this
		integer, intent(in)					:: iNumdata
		integer								:: iRetCode

		! Locals
		integer	:: iErrCode

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Try reserving workspace (failure admittedly possible, and checked for)
		aLlocate( &
			this % rvTimeStamp(iNumData), &
			this % ivNumData(iNumData), &
			this % rmVel(iNumData,3), &
			this % rvT(iNumData), &
			this % rvQ(iNumData), &
			this % rvC(iNumData), &
			this % raCovVel(iNumData,3,3), &
			this % rmCovT(iNumData,3), &
			this % rvVarT(iNumData), &
			this % rmCovQ(iNumData,3), &
			this % rvVarQ(iNumData), &
			this % rmCovC(iNumData,3), &
			this % rvVarC(iNumData), &
			this % rvTheta(iNumData), &
			this % rvPhi(iNumData), &
			this % rvPsi(iNumData), &
			this % rmRotVel(iNumData,3), &
			this % raRotCovVel(iNumData,3,3), &
			this % rmRotCovT(iNumData,3), &
			this % rmRotCovQ(iNumData,3), &
			this % rmRotCovC(iNumData,3), &
			this % rvUstar(iNumData), &
			this % rvUstar_3(iNumData), &
			this % rvH0(iNumData), &
			this % rvHe(iNumData), &
			this % rvFqMolar(iNumData), &
			this % rvFqMass(iNumData), &
			this % rvFcMolar(iNumData), &
			this % rvFcMass(iNumData), &
			stat = iErrCode &
		)
		if(iErrCode /= 0) then
			iRetCode = 1
		end if

	end function ec_Allocate


	function ec_Dump(this) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		integer							:: iRetCode

		! Locals
		integer			:: i
		integer			:: j
		type(DateTime)	:: dt

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check there is something to dump
		if(.not. this % isPrimed) then
			print *, '-- Structure has not been primed with input data --'
			print *
			iRetCode = 1
			return
		end if

		! Print
		print *, "====================================================="
		print *, "Num time steps = ", size(this % rvTimeStamp)
		print *, "Averaging time = ", this % averagingTime
		do i = 1, size(this % rvTimeStamp)
			iRetCode = dt % fromEpoch(this % rvTimeStamp(i))
			print *, dt % toISO(), '   Number of raw data in current step : ', this % ivNumData(i)
			print *, 'Input section ---------------------------------------'
			print "(a, f6.2, 2(1x, f6.2))", "Wind: ", this % rmVel(i,:)
			print "(a, f6.2, 2(1x, f6.2))", "Temp: ", this % rvT(i)
			print "(a, f6.2, 2(1x, f6.2))", "H2O:  ", this % rvQ(i)
			print "(a, f6.2, 2(1x, f6.2))", "CO2:  ", this % rvC(i)
			print *, "Cov(vel):"
			do j = 1, 3
				print "(f7.4,2(',',f7.4))", this % raCovVel(i,j,:)
			end do
			print "(a, f7.4, 2(1x, f7.4))", "Cov(Temp): ", this % rmCovT(i,:)
			print "(a, f7.4, 2(1x, f7.4))", "Var(Temp): ", this % rvVarT(i)
			print "(a, f7.4, 2(1x, f7.4))", "Cov(H2O):  ", this % rmCovQ(i,:)
			print "(a, f7.4, 2(1x, f7.4))", "Cov(CO2):  ", this % rmCovC(i,:)
			if(this % isFilled) then
				print *, 'Output section --------------------------------------'
				print "('Theta, Psi, Phi:',3(1x,f8.4))", this % rvTheta(i), this % rvPhi(i), this % rvPsi(i)
				print "(a, f6.2, 2(1x, f6.2))", "Rotated wind: ", this % rmRotVel(i,:)
				print *, "Rotated cov(vel):"
				do j = 1, 3
					print "(f7.4,2(',',f7.4))", this % raRotCovVel(i,j,:)
				end do
				print "(a, f7.4, 2(1x, f7.4))", "Rotated cov(Temp): ", this % rmRotCovT(i,:)
				print "(a, f7.4, 2(1x, f7.4))", "Rotated cov(H2O):  ", this % rmRotCovQ(i,:)
				print "(a, f7.4, 2(1x, f7.4))", "Rotated cov(CO2):  ", this % rmRotCovC(i,:)
				print "(a, f7.4, 2(1x, f7.4))", "U*(absolute): ", this % rvUstar(i)
				print "(a, f7.4, 2(1x, f7.4))", "U*(finicky):  ", this % rvUstar_3(i)
				print "(a, f7.4, 2(1x, f7.4))", "H0: ", this % rvH0(i)
				print "(a, f7.4, 2(1x, f7.4))", "He: ", this % rvHe(i)
				print "(a, f7.4, 2(1x, f7.4))", "Fq (molar): ", this % rvFqMolar(i)
				print "(a, f7.4, 2(1x, f7.4))", "Fq (mass):  ", this % rvFqMass(i)
				print "(a, f7.4, 2(1x, f7.4))", "Fc (molar): ", this % rvFcMolar(i)
				print "(a, f7.4, 2(1x, f7.4))", "Fc (mass):  ", this % rvFcMass(i)
			end if
		end do

		! Leave
		print *, "====================================================="

	end function ec_Dump


	function ec_getSize(this) result(iNumData)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		integer							:: iNumData

		! Locals
		! --none--

		! Check something is in input section
		if(.not.this % isPrimed) then
			iNumData = 0
			return
		end if

		! Count number of non-missing data in input
		iNumData = size(this % ivNumData)

	end function ec_getSize


	function ec_getAvgTime(this) result(iAveragingTime)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		integer							:: iAveragingTime

		! Locals
		! --none--

		! Retrieve the contents of averaging time field, whatever its contents
		iAveragingTime = this % averagingTime

	end function ec_getAvgTime


	function ec_getNumValidInput(this) result(iNumValid)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		integer							:: iNumValid

		! Locals
		! --none--

		! Check something is in input section
		if(.not.this % isPrimed) then
			iNumValid = 0
			return
		end if

		! Count number of non-missing data in input
		iNumValid = count(this % ivNumData > 0)

	end function ec_getNumValidInput


	! Create an empty multi-hour set, that is an EddyCovData object whose reason-to-be
	! is accepting data from single-hour EddyCovData objects created with SonicData % averages(...).
	!
	! Data from SonidData % averages(...) may then be accepted both right after averaging, and
	! after processing, as you like. Just, let me assume you will be consistent in choosing your
	! way of access, as I'll decide how to assign the logical status flags based on what will
	! be found in the first EddyCovData set you will present.
	!
	! In my view, the cleanest and fastest way to do is:
	!
	!	Invoke EddyCovData % createEmpty(...) for current data set (assuming you know how many hours you have, gaps included)
	!	Loop over all hours:
	!		Read one hourly file into a SonicData object
	!		Average its contents into an hourly EddyCovData object using SonidData % averages(...)
	!		Transfer contents of hourly EddyCovData to the multi-hour EddyCovData using EddyCovData % copy(...)
	!	Once loop done, invoke EddyCovData % process(...)
	!
	! By doing so, you can minimize the code cluttering, and alternating between averaging and processing
	! (of course in my opinion - if you think differently, feel free to act the way you like; in case, I advise you
	! having a look into ec_Copy(...) and figure out what will happen in your specific case)
	!
	function ec_CreateEmpty(this, iNumHours, iAveragingTime) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(out)	:: this
		integer, intent(in)				:: iNumHours		! Number of hours to be contained in this set (1 or more; I'm assuming we know it in advance, but if you like may specify a coarse "large" estimate, 'a la Fortran IV)
		integer, intent(in)				:: iAveragingTime	! Number of seconds in an averaging period (positive, must divide exactly 3600)
		integer							:: iRetCode

		! Locals
		integer	:: iErrCode
		integer	:: iNumBlocks
		integer	:: iNumData

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Clean this object preliminarily (just to make sure in case of failure)
		iErrCode = this % clean()
		if(iErrCode /= 0) then
			iRetCode = 1
			return
		end if

		! Check inputs make sense
		if(iNumHours <= 0) then
			iRetCode = 2
			return
		end if
		if(iAveragingTime <= 0) then
			iRetCode = 3
			return
		end if
		if(mod(3600, iAveragingTime) /= 0) then
			iRetCode = 4
			return
		end if

		! Compute vector sizes, and allocate them preliminarily
		iNumData = iNumHours * (3600 / iAveragingTime)

		! Reserve vector space
		iErrCode = this % reserve(iNumData)
		if(iErrCode /= 0) then
			iRetCode = 5
			return
		end if

		! Set completion indicators to .false.
		this % isPrimed = .false.
		this % isFilled = .false.

		! Initialize all inputs to make any gaps evident in future
		this % rvTimeStamp = NaN_8
		this % ivNumData   = 0
		this % rmVel       = NaN_8
		this % rvT         = NaN_8
		this % rvQ         = NaN_8
		this % rvC         = NaN_8
		this % raCovVel    = NaN_8
		this % rmCovT      = NaN_8
		this % rmCovQ      = NaN_8
		this % rmCovC      = NaN_8
		this % rvVarT      = NaN_8
		this % rvVarQ      = NaN_8
		this % rvVarC      = NaN_8

		! Initialize all outputs to make any gaps evident in future
		this % rvTheta     = NaN_8
		this % rvPhi       = NaN_8
		this % rvPsi       = NaN_8
		this % rmRotVel    = NaN_8
		this % raRotCovVel = NaN_8
		this % rmRotCovT   = NaN_8
		this % rmRotCovQ   = NaN_8
		this % rmRotCovC   = NaN_8
		this % rvUstar     = NaN_8
		this % rvUstar_3   = NaN_8
		this % rvH0        = NaN_8
		this % rvHe        = NaN_8
		this % rvFqMolar   = NaN_8
		this % rvFqMass    = NaN_8
		this % rvFcMolar   = NaN_8
		this % rvFcMass    = NaN_8

		! Confirm averaging time
		this % averagingTime = iAveragingTime

	end function ec_CreateEmpty


	function ec_IsClean(this) result(lPredicateValue)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		logical							:: lPredicateValue

		! Locals
		! --none--

		! Check the object is empty
		lPredicateValue = (.not. this % isPrimed) .and. (.not. this % isFilled) .and. (.not. allocated(this % rvTimeStamp))

	end function ec_IsClean


	function ec_IsEmpty(this) result(lPredicateValue)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		logical							:: lPredicateValue

		! Locals
		! --none--

		! Check the object is empty
		lPredicateValue = (.not. this % isPrimed) .and. (.not. this % isFilled) .and. allocated(this % rvTimeStamp)

	end function ec_IsEmpty


	function ec_IsPrimed(this) result(lPredicateValue)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		logical							:: lPredicateValue

		! Locals
		! --none--

		! Check the object is empty
		lPredicateValue = this % isPrimed

	end function ec_IsPrimed


	function ec_IsFilled(this) result(lPredicateValue)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		logical							:: lPredicateValue

		! Locals
		! --none--

		! Check the object is empty
		lPredicateValue = this % isFilled

	end function ec_IsFilled


	function ec_IsHourly(this) result(lPredicateValue)

		! Routine arguments
		class(EddyCovData), intent(in)	:: this
		logical							:: lPredicateValue

		! Locals
		integer								:: iErrCode
		real(8)								:: rMinStamp
		real(8)								:: rMaxStamp
		integer, dimension(:), allocatable	:: ivYears

		! Check the answer is a trivial .false.
		if(.not. this % isReady()) then
			lPredicateValue = .false.
			return
		end if
		! Post-condition: now we know the object contains some time stamps

		! Check some *valid* time stamp is present
		if(all(.invalid.this % rvTimeStamp)) then
			lPredicateValue = .false.
			return
		end if

		! Find embedding time stamps, and check they span an interval shorter than an hour
		rMinStamp = minval(this % rvTimeStamp, mask = .valid. this % rvTimeStamp)
		rMaxStamp = maxval(this % rvTimeStamp, mask = .valid. this % rvTimeStamp)
		if(rMaxStamp - rMinStamp >= 3600.d0) then
			lPredicateValue = .false.
			return
		end if

		! Check the embedding time stamps belong to the same hour
		iErrCode = timeGetYear([rMinStamp, rMaxStamp], ivYears)
		if(size(ivYears) /= 2) then
			lPredicateValue = .false.
			return
		end if
		if(ivYears(1) /= ivYears(2)) then
			lPredicateValue = .false.
			return
		end if

		! Excluded all the .invalid. causes, we can do nothing else than
		! accepting the truth
		lPredicateValue = .true.

	end function ec_IsHourly


	function ec_GetTimeStamp(this, rvTimeStamp, iDeltaTime) result(iRetCode)

		! Routine argument
		class(EddyCovData), intent(in)						:: this			! A multi-hour object
		real(8), dimension(:), allocatable, intent(out)		:: rvTimeStamp	! The desired copy of object's time stamp (or nothing in case of error)
		integer, intent(out), optional						:: iDeltaTime	! The object's averaging time step
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not.allocated(this % rvTimeStamp)) then
			iRetCode = 1
			return
		end if
		n = size(this % rvTimeStamp)
		if(n < 0) then
			iRetCode = 2
			return
		end if
		if(this % averagingTime <= 0) then
			iRetCode = 3
			return
		end if

		! Get time stamp
		if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
		allocate(rvTimeStamp(n))
		rvTimeStamp = this % rvTimeStamp

		! Retrieve delta time, if requested
		if(present(iDeltaTime)) then
			iDeltaTime = this % averagingTime
		end if

	end function ec_GetTimeStamp


	function ec_GetNumData(this, ivNumData) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		integer, dimension(:), allocatable, intent(out)			:: ivNumData
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(ivNumData)) deallocate(ivNumData)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(ivNumData(n))

		! Retrieve data
		ivNumData = this % ivNumData

	end function ec_GetNumData


	function ec_GetInputData(this, ivNumData, rmVel, rvT, raCovVel, rmCovT, rvVarT) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		integer, dimension(:), allocatable, intent(out)			:: ivNumData
		real(8), dimension(:,:), allocatable, intent(out)		:: rmVel
		real(8), dimension(:), allocatable, intent(out)			:: rvT
		real(8), dimension(:,:,:), allocatable, intent(out)		:: raCovVel
		real(8), dimension(:,:), allocatable, intent(out)		:: rmCovT
		real(8), dimension(:), allocatable, intent(out)			:: rvVarT
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(ivNumData)) deallocate(ivNumData)
		if(allocated(rmVel)) deallocate(rmVel)
		if(allocated(rvT)) deallocate(rvT)
		if(allocated(raCovVel)) deallocate(raCovVel)
		if(allocated(rmCovT)) deallocate(rmCovT)
		if(allocated(rvVarT)) deallocate(rvVarT)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(ivNumData(n))
		allocate(rmVel(n,3))
		allocate(rvT(n))
		allocate(raCovVel(n,3,3))
		allocate(rmCovT(n,3))
		allocate(rvVarT(n))

		! Retrieve data
		ivNumData = this % ivNumData
		rmVel     = this % rmVel
		rvT       = this % rvT
		raCovVel  = this % raCovVel
		rmCovT    = this % rmCovT
		rvVarT    = this % rvVarT

	end function ec_GetInputData


	function ec_GetWindVector(this, rmVel) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		real(8), dimension(:,:), allocatable, intent(out)		:: rmVel
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(rmVel)) deallocate(rmVel)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(rmVel(n,3))

		! Retrieve data
		rmVel     = this % rmVel

	end function ec_getWindVector


	function ec_GetCovWind(this, raCov) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(8), dimension(:,:,:), allocatable, intent(out)	:: raCov
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(raCov)) deallocate(raCov)
		allocate(raCov(size(this % rvTimeStamp),3,3))

		! Get the value desired
		raCov = this % raCovVel

	end function ec_GetCovWind


	function ec_GetInputGases(this, ivNumData, rvQ, rmCovQ, rvVarQ, rvC, rmCovC, rvVarC) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		integer, dimension(:), allocatable, intent(out)			:: ivNumData
		real(8), dimension(:), allocatable, intent(out)			:: rvQ
		real(8), dimension(:,:), allocatable, intent(out)		:: rmCovQ
		real(8), dimension(:), allocatable, intent(out)			:: rvVarQ
		real(8), dimension(:), allocatable, intent(out)			:: rvC
		real(8), dimension(:,:), allocatable, intent(out)		:: rmCovC
		real(8), dimension(:), allocatable, intent(out)			:: rvVarC
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(ivNumData)) deallocate(ivNumData)
		if(allocated(rvQ)) deallocate(rvQ)
		if(allocated(rvC)) deallocate(rvC)
		if(allocated(rmCovQ)) deallocate(rmCovQ)
		if(allocated(rmCovC)) deallocate(rmCovC)
		if(allocated(rvVarQ)) deallocate(rvVarQ)
		if(allocated(rvVarC)) deallocate(rvVarC)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(ivNumData(n))
		allocate(rvQ(n))
		allocate(rvC(n))
		allocate(rmCovQ(n,3))
		allocate(rmCovC(n,3))
		allocate(rvVarQ(n))
		allocate(rvVarC(n))

		! Retrieve data
		ivNumData = this % ivNumData
		rvQ       = this % rvQ
		rvC       = this % rvC
		rmCovQ    = this % rmCovQ
		rmCovC    = this % rmCovC
		rvVarQ    = this % rvVarQ
		rvVarC    = this % rvVarC

	end function ec_GetInputGases


	function ec_GetOutputData(this, rvTheta, rvPhi, rvPsi, rmRotVel, raRotCovVel, rmRotCovT) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		real(8), dimension(:), allocatable, intent(out)			:: rvTheta
		real(8), dimension(:), allocatable, intent(out)			:: rvPhi
		real(8), dimension(:), allocatable, intent(out)			:: rvPsi
		real(8), dimension(:,:), allocatable, intent(out)		:: rmRotVel
		real(8), dimension(:,:,:), allocatable, intent(out)		:: raRotCovVel
		real(8), dimension(:,:), allocatable, intent(out)		:: rmRotCovT
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(rvTheta)) deallocate(rvTheta)
		if(allocated(rvPhi)) deallocate(rvPhi)
		if(allocated(rvPsi)) deallocate(rvPsi)
		if(allocated(rmRotVel)) deallocate(rmRotVel)
		if(allocated(raRotCovVel)) deallocate(raRotCovVel)
		if(allocated(rmRotCovT)) deallocate(rmRotCovT)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(rvTheta(n))
		allocate(rvPhi(n))
		allocate(rvPsi(n))
		allocate(rmRotVel(n,3))
		allocate(raRotCovVel(n,3,3))
		allocate(rmRotCovT(n,3))

		! Retrieve data
		rvTheta      = this % rvTheta
		rvPhi        = this % rvPhi
		rvPsi        = this % rvPsi
		rmRotVel     = this % rmRotVel
		raRotCovVel  = this % raRotCovVel
		rmRotCovT    = this % rmRotCovT

	end function ec_GetOutputData


	function ec_GetCovT(this, rmValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(8), dimension(:,:), allocatable, intent(out)	:: rmValue
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rmValue)) deallocate(rmValue)
		allocate(rmValue(size(this % rvTimeStamp),3))

		! Get the value desired
		rmValue = this % rmCovT

	end function ec_GetCovT


	function ec_GetVarT(this, rvValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvValue
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rvValue)) deallocate(rvValue)
		allocate(rvValue(size(this % rvTimeStamp)))

		! Get the value desired
		rvValue = this % rvVarT

	end function ec_GetVarT


	function ec_GetRotAngles(this, rvTheta, rvPhi, rvPsi) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		real(8), dimension(:), allocatable, intent(out)			:: rvTheta
		real(8), dimension(:), allocatable, intent(out)			:: rvPhi
		real(8), dimension(:), allocatable, intent(out)			:: rvPsi
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(rvTheta)) deallocate(rvTheta)
		if(allocated(rvPhi)) deallocate(rvPhi)
		if(allocated(rvPsi)) deallocate(rvPsi)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(rvTheta(n))
		allocate(rvPhi(n))
		allocate(rvPsi(n))

		! Retrieve data
		rvTheta      = this % rvTheta
		rvPhi        = this % rvPhi
		rvPsi        = this % rvPsi

	end function ec_GetRotAngles


	function ec_GetUstar(this, rvUstar, rvUstar_3) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		real(8), dimension(:), allocatable, intent(out)			:: rvUstar
		real(8), dimension(:), allocatable, intent(out)			:: rvUstar_3
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(rvUstar)) deallocate(rvUstar)
		if(allocated(rvUstar_3)) deallocate(rvUstar_3)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(rvUstar(n))
		allocate(rvUstar_3(n))

		! Retrieve data
		rvUstar      = this % rvUstar
		rvUstar_3    = this % rvUstar_3

	end function ec_GetUstar


	function ec_GetOutputGases(this, rmRotCovQ, rmRotCovC) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)							:: this
		real(8), dimension(:,:), allocatable, intent(out)		:: rmRotCovQ
		real(8), dimension(:,:), allocatable, intent(out)		:: rmRotCovC
		integer													:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isPrimed) then
			iRetCode = 1
			return
		end if

		! Clean output data
		if(allocated(rmRotCovQ)) deallocate(rmRotCovQ)
		if(allocated(rmRotCovC)) deallocate(rmRotCovC)

		! Get array size, and reserve workspace
		n = size(this % rvTimeStamp)
		allocate(rmRotCovQ(n,3))
		allocate(rmRotCovC(n,3))

		! Retrieve data
		rmRotCovQ    = this % rmRotCovQ
		rmRotCovC    = this % rmRotCovC

	end function ec_GetOutputGases


	function ec_GetRotCovVel(this, j, k, rvValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		integer, intent(in)								:: j		! Row index (1..3)
		integer, intent(in)								:: k		! Column index (1..3)
		real(8), dimension(:), allocatable, intent(out)	:: rvValue
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if
		if(j < 1 .or. j > 3) then
			iRetCode = 2
			return
		end if
		if(k < 1 .or. k > 3) then
			iRetCode = 3
			return
		end if

		! Reserve workspace
		if(allocated(rvValue)) deallocate(rvValue)
		allocate(rvValue(size(this % rvTimeStamp)))

		! Get the value desired
		rvValue = this % raRotCovVel(:,j,k)

	end function ec_GetRotCovVel


	function ec_GetRotCovWind(this, raCov) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(8), dimension(:,:,:), allocatable, intent(out)	:: raCov
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(raCov)) deallocate(raCov)
		allocate(raCov(size(this % rvTimeStamp),3,3))

		! Get the value desired
		raCov = this % raRotCovVel

	end function ec_GetRotCovWind


	function ec_GetRotCovT(this, j, rvValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		integer, intent(in)								:: j		! Row index (1..3)
		real(8), dimension(:), allocatable, intent(out)	:: rvValue
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if
		if(j < 1 .or. j > 3) then
			iRetCode = 2
			return
		end if

		! Reserve workspace
		if(allocated(rvValue)) deallocate(rvValue)
		allocate(rvValue(size(this % rvTimeStamp)))

		! Get the value desired
		rvValue = this % rmRotCovT(:,j)

	end function ec_GetRotCovT


	function ec_GetRotCovTemp(this, rmValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(8), dimension(:,:), allocatable, intent(out)	:: rmValue
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rmValue)) deallocate(rmValue)
		allocate(rmValue(size(this % rvTimeStamp),3))

		! Get the value desired
		rmValue = this % rmRotCovT

	end function ec_GetRotCovTemp


	function ec_GetRotCovWater(this, rmValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(8), dimension(:,:), allocatable, intent(out)	:: rmValue
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rmValue)) deallocate(rmValue)
		allocate(rmValue(size(this % rvTimeStamp),3))

		! Get the value desired
		rmValue = this % rmRotCovQ

	end function ec_GetRotCovWater


	function ec_GetRotCovCo2(this, rmValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(8), dimension(:,:), allocatable, intent(out)	:: rmValue
		integer												:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rmValue)) deallocate(rmValue)
		allocate(rmValue(size(this % rvTimeStamp),3))

		! Get the value desired
		rmValue = this % rmRotCovC

	end function ec_GetRotCovCo2


	function ec_GetWind(this, rmPolar, iInterpretation) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)						:: this
		real(4), dimension(:,:), allocatable, intent(out)	:: rmPolar
		integer, intent(in), optional						:: iInterpretation
		integer												:: iRetCode

		! Locals
		integer	:: n
		integer	:: i

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		n = size(this % rvTimeStamp)
		if(allocated(rmPolar)) deallocate(rmPolar)
		allocate(rmPolar(n,3))

		! Get the value desired
		if(present(iInterpretation)) then
			do i = 1, n
				rmPolar(i,:) = CartesianToPolar3(real(this % rmVel(i,:), kind=4), iInterpretation)
			end do
		else
			do i = 1, n
				rmPolar(i,:) = CartesianToPolar3(real(this % rmVel(i,:), kind=4))
			end do
		end if

	end function ec_GetWind


	function ec_GetTemp(this, rvValue) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvValue
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		if(allocated(rvValue)) deallocate(rvValue)
		allocate(rvValue(size(this % rvTimeStamp)))

		! Get the value desired
		rvValue = this % rvT

	end function ec_GetTemp


	function ec_GetH2o(this, rvQ, rvFqMolar, rvFqMass) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvQ
		real(8), dimension(:), allocatable, intent(out)	:: rvFqMolar
		real(8), dimension(:), allocatable, intent(out)	:: rvFqMass
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		n = size(this % rvTimeStamp)
		if(allocated(rvQ))       deallocate(rvQ)
		if(allocated(rvFqMolar)) deallocate(rvFqMolar)
		if(allocated(rvFqMass))  deallocate(rvFqMass)
		allocate(rvQ(n))
		allocate(rvFqMolar(n))
		allocate(rvFqMass(n))

		! Get the value desired
		rvQ       = this % rvQ
		rvFqMolar = this % rvFqMolar
		rvFqMass  = this % rvFqMass

	end function ec_GetH2o


	function ec_GetH2oFluxes(this, rvFqMolar, rvFqMass) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvFqMolar
		real(8), dimension(:), allocatable, intent(out)	:: rvFqMass
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		n = size(this % rvTimeStamp)
		if(allocated(rvFqMolar)) deallocate(rvFqMolar)
		if(allocated(rvFqMass))  deallocate(rvFqMass)
		allocate(rvFqMolar(n))
		allocate(rvFqMass(n))

		! Get the value desired
		rvFqMolar = this % rvFqMolar
		rvFqMass  = this % rvFqMass

	end function ec_GetH2oFluxes


	function ec_GetCo2(this, rvC, rvFcMolar, rvFcMass) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvC
		real(8), dimension(:), allocatable, intent(out)	:: rvFcMolar
		real(8), dimension(:), allocatable, intent(out)	:: rvFcMass
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		n = size(this % rvTimeStamp)
		if(allocated(rvC))       deallocate(rvC)
		if(allocated(rvFcMolar)) deallocate(rvFcMolar)
		if(allocated(rvFcMass))  deallocate(rvFcMass)
		allocate(rvC(n))
		allocate(rvFcMolar(n))
		allocate(rvFcMass(n))

		! Get the value desired
		rvC       = this % rvC
		rvFcMolar = this % rvFcMolar
		rvFcMass  = this % rvFcMass

	end function ec_GetCo2


	function ec_GetCo2Fluxes(this, rvFcMolar, rvFcMass) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvFcMolar
		real(8), dimension(:), allocatable, intent(out)	:: rvFcMass
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		n = size(this % rvTimeStamp)
		if(allocated(rvFcMolar)) deallocate(rvFcMolar)
		if(allocated(rvFcMass))  deallocate(rvFcMass)
		allocate(rvFcMolar(n))
		allocate(rvFcMass(n))

		! Get the value desired
		rvFcMolar = this % rvFcMolar
		rvFcMass  = this % rvFcMass

	end function ec_GetCo2Fluxes


	function ec_GetHeatFluxes(this, rvH0, rvHe) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(in)					:: this
		real(8), dimension(:), allocatable, intent(out)	:: rvH0		! Vertical turbulent sensible heat flux (W/m2)
		real(8), dimension(:), allocatable, intent(out)	:: rvHe		! Vertical turbulent latent heat flux (W/m2)
		integer											:: iRetCode

		! Locals
		integer	:: n

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if(.not. this % isFilled) then
			iRetCode = 1
			return
		end if

		! Reserve workspace
		n = size(this % rvTimeStamp)
		if(allocated(rvH0)) deallocate(rvH0)
		if(allocated(rvHe)) deallocate(rvHe)
		allocate(rvH0(n))
		allocate(rvHe(n))

		! Get the value desired
		rvH0 = this % rvH0
		rvHe = this % rvHe

	end function ec_GetHeatFluxes


	function ec_AddHourly(this, rBaseTime, tEc) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(inout)	:: this			! A multi-hour object
		real(8), intent(in)					:: rBaseTime	! The desired multi-hour object starting time stamp - must be an entire hour; forced to the lowest would it not be
		type(EddyCovData), intent(in)		:: tEc			! The hourly EddyCovData object whose contents should be added to the multi-hourly one
		integer								:: iRetCode

		! Locals
		integer									:: iErrCode
		logical									:: alsoOutputs
		integer									:: n
		integer									:: i
		integer									:: iDeltaTime
		real(8)									:: rTimeStart
		type(DateTime)							:: tDateTimeStart
		real(8), dimension(:), allocatable		:: rvTimeStamp
		integer, dimension(:), allocatable		:: ivTimeIndex
		integer, dimension(:), allocatable		:: ivNumData
		real(8), dimension(:,:), allocatable	:: rmVel
		real(8), dimension(:), allocatable		:: rvT
		real(8), dimension(:), allocatable		:: rvQ
		real(8), dimension(:), allocatable		:: rvC
		real(8), dimension(:,:,:), allocatable	:: raCovVel
		real(8), dimension(:,:), allocatable	:: rmCovT
		real(8), dimension(:,:), allocatable	:: rmCovQ
		real(8), dimension(:,:), allocatable	:: rmCovC
		real(8), dimension(:), allocatable		:: rvVarT
		real(8), dimension(:), allocatable		:: rvVarQ
		real(8), dimension(:), allocatable		:: rvVarC
		real(8), dimension(:), allocatable		:: rvTheta
		real(8), dimension(:), allocatable		:: rvPhi
		real(8), dimension(:), allocatable		:: rvPsi
		real(8), dimension(:,:), allocatable	:: rmRotVel
		real(8), dimension(:,:,:), allocatable	:: raRotCovVel
		real(8), dimension(:,:), allocatable	:: rmRotCovT
		real(8), dimension(:,:), allocatable	:: rmRotCovQ
		real(8), dimension(:,:), allocatable	:: rmRotCovC
		real(8), dimension(:), allocatable		:: rvUstar
		real(8), dimension(:), allocatable		:: rvUstar_3
		real(8), dimension(:), allocatable		:: rvH0
		real(8), dimension(:), allocatable		:: rvHe
		real(8), dimension(:), allocatable		:: rvFqMolar
		real(8), dimension(:), allocatable		:: rvFqMass
		real(8), dimension(:), allocatable		:: rvFcMolar
		real(8), dimension(:), allocatable		:: rvFcMass

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check it makes sense to proceed
		if(tEc % getNumValidInput() <= 0) then
			iRetCode = 1
			return
		end if
		if(.not. tEc % isHourly()) then
			iRetCode = 2
			return
		end if

		! Round the starting time step to its beginning hour, and check it's compatible
		! with a correct DateTime value
		rTimeStart = (int(rBaseTime / 3600.0d0, kind=8) * 3600.0d0)
		iErrCode = tDateTimeStart % fromEpoch(rTimeStart)
		if(iErrCode /= 0) then
			iRetCode = 3
			return
		end if

		! Compute the hourly data's time indexes respect to the time start, as obtained in
		! the preceding step
		iErrCode = tEc % getTimeStamp(rvTimeStamp, iDeltaTime)
		if(iErrCode /= 0) then
			iRetCode = 4
			return
		end if
		iErrCode = timeLinearIndex(rvTimeStamp, iDeltaTime, ivTimeIndex)
		if(iErrCode /= 0) then
			iRetCode = 5
			return
		end if
		ivTimeIndex = ivTimeIndex + (minval(rvTimeStamp, mask = .valid.rvTimeStamp) - rTimeStart) / iDeltaTime
		! Post-condition: A finite time index is available

		! Limit time index to range of current object's time stamp
		n = tEc % getSize()
		do i = 1, n
			if(ivTimeIndex(i) > size(this % rvTimeStamp)) ivTimeIndex(i) = 0
		end do

		! Check some transfer remains to do (it might not, would the hour be off-range)
		if(count(ivTimeIndex > 0) <= 0) then
			iRetCode = -1
			return
		end if

		! Check averaging time is left unchanged (i.i., same as desired .and. no configuration change)
		if(this % averagingTime /= tEc % getAvgTime()) then
			iRetCode = 6
			return
		end if

		! Update state incorporating inputs
		iErrCode = tEc % getInputData(ivNumData, rmVel, rvT, raCovVel, rmCovT, rvVarT)
		if(iErrCode /= 0) then
			iRetCode = 7
			return
		end if
		iErrCode = tEc % getInputGases(ivNumData, rvQ, rmCovQ, rvVarQ, rvC, rmCovC, rvVarC)
		if(iErrCode /= 0) then
			iRetCode = 8
			return
		end if
		if(.not. this % isPrimed) then
			this % isPrimed = .true.
			this % isFilled = .false.
		end if

		! Update the part of state incorporating output, if it is defined
		alsoOutputs = tEc % isFull()
		if(alsoOutputs) then
			iErrCode = tEc % getOutputData(rvTheta, rvPhi, rvPsi, rmRotVel, raRotCovVel, rmRotCovT)
			if(iErrCode /= 0) then
				iRetCode = 9
				return
			end if
			iErrCode = tEc % getOutputGases(rmRotCovQ, rmRotCovC)
			if(iErrCode /= 0) then
				iRetCode = 10
				return
			end if
			iErrCode = tEc % getH2oFluxes(rvFqMolar, rvFqMass)
			if(iErrCode /= 0) then
				iRetCode = 11
				return
			end if
			iErrCode = tEc % getCo2Fluxes(rvFcMolar, rvFcMass)
			if(iErrCode /= 0) then
				iRetCode = 12
				return
			end if
			iErrCode = tEc % getHeatFluxes(rvH0, rvHe)
			if(iErrCode /= 0) then
				iRetCode = 13
				return
			end if
			iErrCode = tEc % getUstar(rvUstar, rvUstar_3)
			if(iErrCode /= 0) then
				iRetCode = 14
				return
			end if
			if(.not. this % isFilled) then
				this % isPrimed = .true.
				this % isFilled = .true.
			end if
		end if

		! Perform transfers
		do i = 1, n
			if(ivTimeIndex(i) > 0) then
				this % rvTimeStamp(ivTimeIndex(i))  = rvTimeStamp(i)
				this % ivNumData(ivTimeIndex(i))    = ivNumData(i)
				this % rmVel(ivTimeIndex(i),:)      = rmVel(i,:)
				this % rvT(ivTimeIndex(i))          = rvT(i)
				this % rvQ(ivTimeIndex(i))          = rvQ(i)
				this % rvC(ivTimeIndex(i))          = rvC(i)
				this % raCovVel(ivTimeIndex(i),:,:) = raCovVel(i,:,:)
				this % rmCovT(ivTimeIndex(i),:)     = rmCovT(i,:)
				this % rmCovQ(ivTimeIndex(i),:)     = rmCovQ(i,:)
				this % rmCovC(ivTimeIndex(i),:)     = rmCovC(i,:)
				this % rvVarT(ivTimeIndex(i))       = rvVarT(i)
				this % rvVarQ(ivTimeIndex(i))       = rvVarQ(i)
				this % rvVarC(ivTimeIndex(i))       = rvVarC(i)
				if(alsoOutputs) then
					this % rvTheta(ivTimeIndex(i))         = rvTheta(i)
					this % rvPhi(ivTimeIndex(i))           = rvPhi(i)
					this % rvPsi(ivTimeIndex(i))           = rvPsi(i)
					this % rmRotVel(ivTimeIndex(i),:)      = rmRotVel(i,:)
					this % raRotCovVel(ivTimeIndex(i),:,:) = raRotCovVel(i,:,:)
					this % rmRotCovT(ivTimeIndex(i),:)     = rmRotCovT(i,:)
					this % rmRotCovQ(ivTimeIndex(i),:)     = rmRotCovQ(i,:)
					this % rmRotCovC(ivTimeIndex(i),:)     = rmRotCovC(i,:)
					this % rvUstar(ivTimeIndex(i))         = rvUstar(i)
					this % rvUstar_3(ivTimeIndex(i))       = rvUstar_3(i)
					this % rvH0(ivTimeIndex(i))            = rvH0(i)
					this % rvHe(ivTimeIndex(i))            = rvHe(i)
					this % rvFqMolar(ivTimeIndex(i))       = rvFqMolar(i)
					this % rvFqMass(ivTimeIndex(i))        = rvFqMass(i)
					this % rvFcMolar(ivTimeIndex(i))       = rvFcMolar(i)
					this % rvFcMass(ivTimeIndex(i))        = rvFcMass(i)
				end if
			end if
		end do

	end function ec_AddHourly


	! Minimalistic eddy covariance calculations, molded after
	! EDDY.FOR, described in
	!
	!    R.Sozzi, M.Favaron, "Sonic Anemometry and Thermometry: theoretical basis and data-processing software",
	!    Environmental Software, 11, 4, 1996
	!
	! Actually, I've made many little changes (whose effect is purely aesthetical)
	! for compatibility with modern Fortran, and to make code clearer to understand.
	! (Mauri Favaron)
	!
	function ec_Process(this, iNumRot, rZ_in) result(iRetCode)

		! Routine arguments
		class(EddyCovData), intent(inout)	:: this			! A multi-hour object
		integer, intent(in), optional		:: iNumRot		! Number of reference rotations to make (2 or 3; default: 2)
		real(8), intent(in), optional		:: rZ_in		! Station altitude above MSL [m]
		integer								:: iRetCode

		! Locals
		integer									:: iErrCode
		integer									:: iRotations
		integer									:: i
		integer									:: n
		real(8)									:: rZ
		real(8)									:: rVel
		real(8)									:: rVel3
		real(8)									:: cos_the
		real(8)									:: sin_the
		real(8)									:: cos_phi
		real(8)									:: sin_phi
		real(8)									:: cos_psi
		real(8)									:: sin_psi
		real(8)									:: sin_cos
		real(8)									:: costhe2
		real(8)									:: sinthe2
		real(8)									:: cosphi2
		real(8)									:: sinphi2
		real(8)									:: cospsi2
		real(8)									:: sinpsi2
		real(8)									:: psi
		real(8)									:: um2, vm2, wm2
		real(8)									:: ut2, vt2, wt2
		real(8)									:: uq2, vq2, wq2
		real(8)									:: uc2, vc2, wc2
		real(8)									:: su2, sv2, sw2
		real(8)									:: uv2, uw2, vw2
		real(8)									:: um3, vm3, wm3
		real(8)									:: ut3, vt3, wt3
		real(8)									:: uq3, vq3, wq3
		real(8)									:: uc3, vc3, wc3
		real(8)									:: su3, sv3, sw3
		real(8)									:: uv3, uw3, vw3
		real(8), dimension(:), allocatable		:: rvTa
		real(8)									:: tc
		real(8)									:: qd
		real(8)									:: qc
		real(8)									:: cd
		real(8)									:: cdv
		real(8)									:: mix_factor
		real(8)									:: wt_cor
		real(8)									:: lambda
		real									:: rPa

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Set the desired number of rotations
		if(present(iNumRot)) then
			iRotations = max(min(iNumRot,3),2)
		else
			iRotations = 2
		end if

		! Set processing height
		if(present(rZ_in)) then
			rZ = rZ_in
		else
			rZ = 0.d0	! Default: perform water and carbon dioxide processing with reference to mean sea level
		end if

		! Check something can be really made
		if(.not. this % isReady()) then
			iRetCode = 1
			return
		end if

		! Initialize
		n = size(this % rvTimeStamp)

		! Stage 1: Compute and execute rotations
		do i = 1, n

			! Pre-assign rotation angles to zero, so that in case of no action a defined state is
			! anyway defined
			this % rvTheta(i) = 0.
			this % rvPhi(i)   = 0.
			this % rvPsi(i)   = 0.

			! Set horizontal speed, and horizontal versor components
			rVel = sqrt(this % rmVel(i,1)**2 + this % rmVel(i,2)**2)
			if(rVel > 0.) then
				cos_the = this % rmVel(i,1) / rVel
				sin_the = this % rmVel(i,2) / rVel
			else
				cos_the = NaN_8
				sin_the = NaN_8
			end if
			costhe2 = cos_the ** 2
			sinthe2 = sin_the ** 2
			sin_cos = 2. * sin_the * cos_the
			! Note: By the properties of versor components and trigonometry, cos_the = cos(theta), sin_the = sin(theta)
			!       where 'theta' is the first rotation angle

			! Store first rotation angle
			this % rvTheta(i) = 180./PI*atan2(this % rmVel(i,2), this % rmVel(i,1))
			if(this % rvTheta(i) < 0.0) this % rvTheta(i) = this % rvTheta(i) + 360.0

			! Apply first rotation to vectors and matrices
			! 1) Mean wind components
			this % rmRotVel(i,1) =  this % rmVel(i,1) * cos_the + this % rmVel(i,2) * sin_the
			this % rmRotVel(i,2) = -this % rmVel(i,1) * sin_the + this % rmVel(i,2) * cos_the
			this % rmRotVel(i,3) =  this % rmVel(i,3)
			! 2) Wind-temperature covariances
			this % rmRotCovT(i,1) =  this % rmCovT(i,1) * cos_the + this % rmCovT(i,2) * sin_the
			this % rmRotCovT(i,2) = -this % rmCovT(i,1) * sin_the + this % rmCovT(i,2) * cos_the
			this % rmRotCovT(i,3) =  this % rmCovT(i,3)
			! 2) Wind-water covariances
			this % rmRotCovQ(i,1) =  this % rmCovQ(i,1) * cos_the + this % rmCovQ(i,2) * sin_the
			this % rmRotCovQ(i,2) = -this % rmCovQ(i,1) * sin_the + this % rmCovQ(i,2) * cos_the
			this % rmRotCovQ(i,3) =  this % rmCovQ(i,3)
			! 2) Wind-co2 covariances
			this % rmRotCovC(i,1) =  this % rmCovC(i,1) * cos_the + this % rmCovC(i,2) * sin_the
			this % rmRotCovC(i,2) = -this % rmCovC(i,1) * sin_the + this % rmCovC(i,2) * cos_the
			this % rmRotCovC(i,3) =  this % rmCovC(i,3)
			! 3) Wind covariances
			this % raRotCovVel(i,1,1) = this % raCovVel(i,1,1)*costhe2 + this % raCovVel(i,2,2)*sinthe2 + &
				this % raCovVel(i,1,2)*sin_cos
			this % raRotCovVel(i,2,2) = this % raCovVel(i,1,1)*sinthe2 + this % raCovVel(i,2,2)*costhe2 - &
				this % raCovVel(i,1,2)*sin_cos
			this % raRotCovVel(i,3,3) = this % raCovVel(i,3,3)
			this % raRotCovVel(i,1,2) =  0.5*sin_cos*(this % raCovVel(i,2,2) - this % raCovVel(i,1,1)) + &
				this % raCovVel(i,1,2)*(costhe2-sinthe2)
			this % raRotCovVel(i,1,3) =  this % raCovVel(i,1,3)*cos_the + this % raCovVel(i,2,3)*sin_the
			this % raRotCovVel(i,2,3) = -this % raCovVel(i,1,3)*sin_the + this % raCovVel(i,2,3)*cos_the
			this % raRotCovVel(i,2,1) = this % raRotCovVel(i,1,2)
			this % raRotCovVel(i,3,1) = this % raRotCovVel(i,1,3)
			this % raRotCovVel(i,3,2) = this % raRotCovVel(i,2,3)

			! Set vertical speed, and vertical-horizontal versor components
			rVel3 = sqrt(this % rmVel(i,1)**2 + this % rmVel(i,2)**2 + this % rmVel(i,3)**2)
			if(rVel3 > 0.) then
				sin_phi = this % rmVel(i,3) / rVel3
				cos_phi = rVel / rVel3
			else
				sin_phi = NaN_8
				cos_phi = NaN_8
			end if
			sin_cos = 2.*sin_phi*cos_phi
			sinphi2 = sin_phi*sin_phi
			cosphi2 = cos_phi*cos_phi
			this % rvPhi(i) = 180./PI*atan2(this % rmVel(i,3), rVel)

			! Perform second rotation
			! 1) Mean wind components
			um2 =  this % rmRotVel(i,1)*cos_phi + this % rmRotVel(i,3)*sin_phi
			vm2 =  this % rmRotVel(i,2)
			wm2 = -this % rmRotVel(i,1)*sin_phi + this % rmRotVel(i,3)*cos_phi
			this % rmRotVel(i,1) = um2
			this % rmRotVel(i,2) = vm2
			this % rmRotVel(i,3) = wm2
			! 2) Wind-temperature covariances
			ut2 =  this % rmRotCovT(i,1)*cos_phi + this % rmRotCovT(i,3)*sin_phi
			vt2 =  this % rmRotCovT(i,2)
			wt2 = -this % rmRotCovT(i,1)*sin_phi + this % rmRotCovT(i,3)*cos_phi
			this % rmRotCovT(i,1) = ut2
			this % rmRotCovT(i,2) = vt2
			this % rmRotCovT(i,3) = wt2
			! 2) Wind-water covariances
			uq2 =  this % rmRotCovQ(i,1)*cos_phi + this % rmRotCovQ(i,3)*sin_phi
			vq2 =  this % rmRotCovQ(i,2)
			wq2 = -this % rmRotCovQ(i,1)*sin_phi + this % rmRotCovQ(i,3)*cos_phi
			this % rmRotCovQ(i,1) = uq2
			this % rmRotCovQ(i,2) = vq2
			this % rmRotCovQ(i,3) = wq2
			! 2) Wind-co2 covariances
			uc2 =  this % rmRotCovC(i,1)*cos_phi + this % rmRotCovC(i,3)*sin_phi
			vc2 =  this % rmRotCovC(i,2)
			wc2 = -this % rmRotCovC(i,1)*sin_phi + this % rmRotCovC(i,3)*cos_phi
			this % rmRotCovC(i,1) = uc2
			this % rmRotCovC(i,2) = vc2
			this % rmRotCovC(i,3) = wc2
			! 3) Wind covariances
			su2 =  this % raRotCovVel(i,1,1)*cosphi2 + this % raRotCovVel(i,3,3)*sinphi2 + &
				this % raRotCovVel(i,1,3)*sin_cos
			sv2 =  this % raRotCovVel(i,2,2)
			sw2 =  this % raRotCovVel(i,1,1)*sinphi2 + this % raRotCovVel(i,3,3)*cosphi2 - &
				this % raRotCovVel(i,1,3)*sin_cos
			uv2 =  this % raRotCovVel(i,1,2)*cos_phi + this % raRotCovVel(i,2,3)*sin_phi
			uw2 =  sin_cos/2.*(this % raRotCovVel(i,3,3)-this % raRotCovVel(i,1,1)) + &
				this % raRotCovVel(i,1,3)*(cosphi2-sinphi2)
			vw2 = -this % raRotCovVel(i,1,2)*sin_phi + this % raRotCovVel(i,2,3)*cos_phi
			this % raRotCovVel(i,1,1) = su2
			this % raRotCovVel(i,2,2) = sv2
			this % raRotCovVel(i,3,3) = sw2
			this % raRotCovVel(i,1,2) = uv2
			this % raRotCovVel(i,2,1) = uv2
			this % raRotCovVel(i,1,3) = uw2
			this % raRotCovVel(i,3,1) = uw2
			this % raRotCovVel(i,2,3) = vw2
			this % raRotCovVel(i,3,2) = vw2

			! If required, compute the third rotation
			if(iNumRot >= 3) then
				if(abs(vw2) < 1.e-6 .and. abs(sv2-sw2) < 1.e-6) then

					! The third rotation angle is not defined: assume 0. degrees rotation
					this % rvPsi(i) = 0

				else

					! Set
					psi     = 0.5*ATAN2(2.*vw2,sv2-sw2)
					sin_psi = sin(psi)
					cos_psi = cos(psi)
					sin_cos = 2.*sin_psi*cos_psi
					sinpsi2 = sin_psi*sin_psi
					cospsi2 = cos_psi*cos_psi
					this % rvPsi(i) = psi*180./PI

					! Execute third rotation
					! 1) Mean wind components
					um3 =  um2
					vm3 =  vm2*cos_psi+wm2*sin_psi
					wm3 = -vm2*sin_psi+wm2*cos_psi
					this % rmRotVel(i,1) = um3
					this % rmRotVel(i,2) = vm3
					this % rmRotVel(i,3) = wm3
					! 2) Wind-temperature covariances
					ut3 =  ut2
					vt3 =  vt2*cos_psi+wt2*sin_psi
					wt3 = -vt2*sin_psi+wt2*cos_psi
					this % rmRotCovT(i,1) = ut3
					this % rmRotCovT(i,2) = vt3
					this % rmRotCovT(i,3) = wt3
					! 2) Wind-water covariances
					uq3 =  uq2
					vq3 =  vq2*cos_psi+wq2*sin_psi
					wq3 = -vq2*sin_psi+wq2*cos_psi
					this % rmRotCovQ(i,1) = uq3
					this % rmRotCovQ(i,2) = vq3
					this % rmRotCovQ(i,3) = wq3
					! 2) Wind-co2 covariances
					uc3 =  uc2
					vc3 =  vc2*cos_psi+wc2*sin_psi
					wc3 = -vc2*sin_psi+wc2*cos_psi
					this % rmRotCovC(i,1) = uc3
					this % rmRotCovC(i,2) = vc3
					this % rmRotCovC(i,3) = wc3
					! 3) Wind covariances
					su3 =  su2
					sv3 =  sv2*cospsi2+sw2*sinpsi2+vw2*sin_cos
					sw3 =  sv2*sinpsi2+sw2*cospsi2-vw2*sin_cos
					uv3 =  uv2*cos_psi+uw2*sin_psi
					uw3 = -uv2*sin_psi+uw2*cos_psi
					vw3 =  sin_cos/2.*(sw2-sv2)+vw2*(cospsi2-sinpsi2)
					this % raRotCovVel(i,1,1) = su2
					this % raRotCovVel(i,2,2) = sv2
					this % raRotCovVel(i,3,3) = sw2
					this % raRotCovVel(i,1,2) = uv2
					this % raRotCovVel(i,2,1) = uv2
					this % raRotCovVel(i,1,3) = uw2
					this % raRotCovVel(i,3,1) = uw2
					this % raRotCovVel(i,2,3) = vw2
					this % raRotCovVel(i,3,2) = vw2

				end if
			end if

		end do

		! Stage 2: Common calculations

		! Friction velocity
		do i = 1, n
			this % rvUstar(i) = (this % raRotCovVel(i,1,3)**2 + this % raRotCovVel(i,2,3)**2)**0.25d0		! Always defined, makes sense with 2 or 3 rotations  (UW^2+VW^2)^(1/4)
			if(this % raRotCovVel(i,1,3) < 0.) then
				this % rvUstar_3(i) = sqrt(-this % raRotCovVel(i,1,3))						! Only defined when the vertical gradient of turbulemce is negative; makes sense with 3 rotations
			else
				this % rvUstar_3(i) = NaN_8
			end if
		end do

		! Stage 3: Water and carbon dioxide
		allocate(rvTa(n))
		rvTa = this % rvT + 273.15d0
		rPa = AirPressure(real(rZ, kind=4))
		do i = 1, n

			! Air molar concentration
			cd = 1000.0d0 * AirDensity(real(rvTa(i), kind=4), real(rPa, kind=4))/MOL_Air	! [g/m3] / [g/mmol] = [g/m3] * [mmol/g] = [mmol/m3]

			! Water specific processing
			qd  = this % rvQ(i) / cd														! Adimensional ratio
			cdv = cd + this % rvQ(i)														! Molar concentration of moist air [mmol/m3]
			tc  = cdv * this % rmRotCovT(i,3) / rvTa(i)										! [mmol/m3] [m K/s] / [K] = [mmol/(m2 s)]
			this % rvFqMolar(i) = this % rmRotCovQ(i,3) + qd * (tc + this % rmRotCovT(i,3))	! [mmol/(m2 s)]
			this % rvFqMass(i)  = MOL_H2O * this % rvFqMolar(i)								! [mg/(m2 s)]

			! Thermal effect correction (Schotanus)
			mix_factor     = MOL_H2O / AirDensity(real(rvTa(i), kind=4), real(rPa, kind=4))/1000.d0
			wt_cor         = this % rmRotCovT(i,3) - 0.51d0 * mix_factor * rvTa(i) * this % rmRotCovQ(i,3)
			this % rvH0(i) = RhoCp(real(rvTa(i), kind=4), real(rPa, kind=4)) * wt_cor

			! Latent heat
			lambda         = 2500.8d0 - 2.36d0 * rvTa(i) + 0.0016d0 * rvTa(i)**2 - 0.00006d0 * rvTa(i)**3	! Latent condensation heat foe water [J/g] (temperature in °C)
			this % rvHe(i) = lambda/1000.d0 * this % rvFqMass(i)

			! Carbon dioxide specific processing
			qc = this % rvC(i) / cd															! Dimensionless ratio
			this % rvFcMolar(i) = this % rmRotCovC(i,3) + qc * (tc + this % rmRotCovQ(i,3))	! [mmol/(m2 s)]
			this % rvFcMass(i)  = MOL_CO2 * this % rvFcMolar(i)								! [mg/(m2 s)]

  		end do
  		deallocate(rvTa)

		! Processing did complete: inform users, by setting the appropriate completion flag
		this % isFilled = .true.

	end function ec_Process


	! *********************
	! * Internal routines *
	! *********************

	! Transform horizontal wind components wind from polar to cartesian form
		! (speed is surely greater than 1.e-6)
	subroutine uvWind(vel, dir, u, v)

		! Routine arguments
		real, intent(in)	:: vel
		real, intent(in)	:: dir
		real, intent(out)	:: u
		real, intent(out)	:: v

		! Locals
		! --none--

		! Perform the transform desired
		u = vel * sin(dir*ToRad)
		v = vel * cos(dir*ToRad)

	end subroutine uvWind


	! Transform horizontal wind components wind from cartesian to polar form
	! (speed is surely greater than 1.e-6)
	subroutine veldirWind(u, v, vel, dir)

		! Routine arguments
		real, intent(in)	:: u
		real, intent(in)	:: v
		real, intent(out)	:: vel
		real, intent(out)	:: dir

		! Locals
		! --none--

		! Perform the transform desired
		vel = sqrt(u**2 + v**2)
		dir = atan2(u, v)*ToDeg
		dir = mod(dir, 360.)
		if(dir < 0.) dir = dir + 360.

	end subroutine veldirWind

end module pbl_wind


! pbl_simil  : Fortran module, providing support to Monin-Obukhov
!              (surface layer) similarity.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_simil

    use pbl_base
    use pbl_wind
    use pbl_thermo

    implicit none
    
    private
    
    ! Public interface
    ! 0.Constants
    public	:: USTAR_PERMISSIVE
    public	:: USTAR_FINICKY
    public	:: MTD_BUSINGER
    public	:: MTD_VANULDEN_HOLTSLAG
    public	:: MTD_BELIJAARS_HOLTSLAG
    public	:: MTD_CARL
    public	:: MOL_H2O
    public	:: MOL_CO2
    public	:: MOL_AIR
    
    ! 1.Turbulence
    public	:: FrictionVelocity
    public	:: SensibleHeatFlux
    public	:: WindCorrelation
    ! 2.Stability, and stability-related
    public	:: wStar
    ! 3.Universal similarity functions
    public	:: psih
    public	:: psim
    ! 4.Vertical profiles
    public	:: WindProfile
    public	:: TempProfile
    public	:: HorizontalWindVarProfile
    public	:: VerticalWindVarProfile
    public	:: TKEDissipationProfile
    public	:: KolmogorovConstants
    
    ! Constants (please do not change)
    
    integer, parameter	:: USTAR_PERMISSIVE = 0
    integer, parameter	:: USTAR_FINICKY    = 1
    
    integer, parameter	:: MTD_BUSINGER           = 1
    integer, parameter	:: MTD_VANULDEN_HOLTSLAG  = 2
    integer, parameter	:: MTD_BELIJAARS_HOLTSLAG = 3
    integer, parameter	:: MTD_CARL               = 4
    
    real(8), parameter	:: MOL_AIR = 28.96d0
    real(8), parameter	:: MOL_H2O = 18.0153d0
    real(8), parameter	:: MOL_CO2 = 44.0100d0
    
contains

	function FrictionVelocity(tEc, iMode, rvUstar) result(iRetCode)
	
		! Routine arguments
		type(EddyCovData), intent(in)					:: tEc
		integer, intent(in), optional					:: iMode
		real(8), dimension(:), allocatable, intent(out)	:: rvUstar
		integer											:: iRetCode
		
		! Locals
		integer							:: i
		integer							:: iErrCode
		integer							:: iModeIn
		integer							:: n
		real(8), dimension(:), allocatable	:: rvUW
		real(8), dimension(:), allocatable	:: rvVW
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check something can be made
		if(.not. tEc % isFull()) then
			iRetCode = 1
			return
		end if
		
		! Assign mode
		if(present(iMode)) then
			iModeIn = iMode
		else
			iModeIn = USTAR_PERMISSIVE
		end if
		
		! Reserve workspace
		iErrCode = tEc % getRotCovVel(1,3,rvUW)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		iErrCode = tEc % getRotCovVel(2,3,rvVW)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		n = size(rvUW)
		if(allocated(rvUstar)) deallocate(rvUstar)
		allocate(rvUstar(n))
		
		! Compute the friction velocity
		select case(iMode)
		case(USTAR_PERMISSIVE)
			rvUstar = (rvUW**2 + rvVW**2)**0.25d0
		case(USTAR_FINICKY)
			where(rvUW < 0.)
				rvUstar = sqrt(-rvUW)
			elsewhere
				rvUstar = NaN_8
			endwhere
		case default
			iRetCode = 2
		end select
		
	end function FrictionVelocity
    

	function SensibleHeatFlux(tEc, rvH0) result(iRetCode)
	
		! Routine arguments
		type(EddyCovData), intent(in)					:: tEc
		real(8), dimension(:), allocatable, intent(out)	:: rvH0
		integer											:: iRetCode
		
		! Locals
		integer								:: iErrCode
		integer								:: iModeIn
		integer								:: i
		integer								:: n
		real(8), dimension(:), allocatable	:: rvWT
		real(8), dimension(:), allocatable	:: rvTemp
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check something can be made
		if(.not. tEc % isFull()) then
			iRetCode = 1
			return
		end if
		
		! Reserve workspace
		iErrCode = tEc % getRotCovT(3,rvWT)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		iErrCode = tEc % getTemp(rvTemp)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		n = size(rvWT)
		if(allocated(rvH0)) deallocate(rvH0)
		allocate(rvH0(n))
		
		! Compute the sensible heat flux on vertical direction
		do i = 1, n
			rvH0(i) = rvWT(i) * RhoCp(real(rvTemp(i),kind=4) + 273.15)
		end do
		
	end function SensibleHeatFlux
	
	
	function WindCorrelation(tEc, raWindCorr) result(iRetCode)
	
		! Routine arguments
		type(EddyCovData), intent(in)						:: tEc
		real(8), dimension(:,:,:), allocatable, intent(out)	:: raWindCorr
		integer												:: iRetCode
		
		! Locals
		integer								:: iErrCode
		integer								:: iModeIn
		integer								:: i
		integer								:: j
		integer								:: k
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check something can be made
		if(.not. tEc % isFull()) then
			iRetCode = 1
			return
		end if
		
		! Reserve workspace
		iErrCode = tEc % getRotCovWind(raWindCorr)
		if(iErrCode /= 0) then
			iRetCode = 2
			return
		end if
		
		! Compute the three correlation coefficients, and leave variances unscaled
		! (so transform is reversible)
		do i = 1, size(raWindCorr, dim=1)
			do j = 1, 2
				do k = j+1, 3
					raWindCorr(i,j,k) = raWindCorr(i,j,k) / sqrt(raWindCorr(i,j,j)*raWindCorr(i,k,k))
					raWindCorr(i,k,j) = raWindCorr(i,j,k)
				end do
			end do
		end do
		
	end function WindCorrelation
	

	Function wStar(Ta,H0,zi) result(ws)
	
		! Routine arguments
		real, intent(in)	:: Ta	! Air temperature (K)
		real, intent(in)	:: H0	! Turbulent sensible heat flux (W/m2)
		real, intent(in)	:: zi	! Mixing height (mù
		real				:: ws
		
		! Locals
		real	:: rc
		
		! Constants
		real, parameter	:: G = 9.807
		
		! Check something can be made
		ws = NaN
		if(Ta <= 0. .or. zi < 0.) return
		
		! Compute the Deardoff velocity
		if(H0 < 0.) then
			ws = 0.
		else
			rc = RhoCp(Ta)
			if(.invalid.rc) return
			ws = (G * zi * H0 / (rc * Ta))**0.33333
		end if

	end function wStar
      
      
	function psih(zr, L, method) result(rPsiH)
	
		! Routine arguments
		real, intent(in)				:: zr		! Reference height (m)
		real, intent(in)				:: L		! Obukhov length (m)
		integer, intent(in), optional	:: method	! Method for stable part (MTD_BUSINGER: Businger; MTD_VANULDEN_HOLTSLAG:van Ulden-Holtslag, default; MTD_BELIJAARS_HOLTSLAG:Belijaars-Holtslag)
		real							:: rPsiH
		
		! Locals
		real	:: S	! Stability parameter at height 'zr'
		real	:: y
		real	:: exz
		real	:: c1
		real	:: c2
		real	:: c3
		integer	:: iMethod
		
		! Check something can be made
		rPsiH = NaN
		if(L /= 0.0) return
		S     = zr/L
		
		! Compute the desired quantity
		if(L < 0.) then
		
			! Convective part by Businger relation
			y = sqrt(1.-16.*S)
			rPsiH = 2.*alog((1.+y)/2.)
			
		else
		
			! Assign actual method
			if(present(method)) then
				iMethod = method
			else
				iMethod = MTD_VANULDEN_HOLTSLAG
			end if
			
			! Perform computing
			select case(iMethod)
			case(MTD_BUSINGER)
				rPsiH = -5. * S
			case(MTD_VANULDEN_HOLTSLAG)
				rPsiH = -17. * (1.-exp(-0.29*S))
			case(MTD_BELIJAARS_HOLTSLAG)
				exz = exp(-0.35*S)
				c1  = 1.+0.666667*S
				c2  = S-5./0.35
				c3  = 0.667*5./0.35
				rPsiH = -c1**1.5 - 0.667*c2*exz - c3 + 1.
			end select
		
		end if
		
	end function psih
    

	function psim(zr, L, stableMethod, convectiveMethod) result(rPsiM)
	
		! Routine arguments
		real, intent(in)				:: zr				! Reference height (m)
		real, intent(in)				:: L				! Obukhov length (m)
		integer, intent(in), optional	:: stableMethod		! Method for stable part (MTD_BUSINGER: Businger; MTD_VANULDEN_HOLTSLAG:van Ulden-Holtslag, default; MTD_BELIJAARS_HOLTSLAG:Belijaars-Holtslag)
		integer, intent(in), optional	:: convectiveMethod	! Method for convective part (MTD_BUSINGER: Businger, default; MTD_VANULDEN_HOLTSLAG:van Ulden-Holtslag; MTD_CARL:Carl)
		real							:: rPsiM
		
		! Locals
		real	:: S	! Stability parameter at height 'zr'
		real	:: x
		integer	:: iMethodStable
		integer	:: iMethodConvective
		
		! Constant
		real, parameter :: a = 0.7
		real, parameter :: b = 0.75
		real, parameter :: c = 5.
		real, parameter :: d = 0.35
		
		! Check something can be made
		rPsiM = NaN
		if(L /= 0.0) return
		S     = zr/L
		
		! Compute the desired quantity
		if(L < 0.) then ! Convective part
		
			! Assign actual method
			if(present(convectiveMethod)) then
				iMethodConvective = convectiveMethod
			else
				iMethodConvective = MTD_BUSINGER
			end if
			
			! Perform computing
			select case(iMethodConvective)
			case(MTD_BUSINGER)
				x    = (1.-16.*S)**0.25
				rPsiM = log((1.+x*x)/2.*((1.+x)/2.)**2) - 2.*atan(x) + 1.570796
			case(MTD_VANULDEN_HOLTSLAG)
				rPsiM = (1.-16.*S)**0.25 - 1.
			case(MTD_BELIJAARS_HOLTSLAG)
				x      = (1.-16.*S)**0.3333
				rPsiM = 1.5 * log(x*x+x+1.) - 1.7320508 * atan((2.*x+1)/1.7320508) + 0.165881
			end select
			
		else ! Stable
		
			! Assign actual method
			if(present(stableMethod)) then
				iMethodStable = stableMethod
			else
				iMethodStable = MTD_VANULDEN_HOLTSLAG
			end if
			
			! Perform computing
			select case(iMethodStable)
			case(MTD_BUSINGER)
				rPsiM = -5.*S
			case(MTD_VANULDEN_HOLTSLAG)
				rPsiM = -17. * (1.-exp(-0.29*S))
			case(MTD_CARL)
				rPsiM = -a*S-b*(S-c/d)*exp(-d*S)-b*c/d
			end select
		
		end if
		
	end function psim
	      

	! Reference: R.Sozzi, T.Georgiadis, M.Valentivi, "Introduzione alla turbolenza atmosferica: Concetti,
	! stime, misure", Pitagora Editrice (2002)
	!
	! Code is an extensive refactoring of R.Sozzi's WIND_PBL routine, written in 2000
	function WindProfile(iglo,z,zr,vr,dir,z0,hmix,us,hlm,u,v) result(iRetCode)
	
		! Routine arguments
		integer, intent(in)					:: iglo	! Hemisphere (0: Southern, 1: Northern)
		real(8), dimension(:), intent(in)	:: z	! Heights above ground (m)
		real(8), intent(in)					:: zr	! Wind measurement height above ground (m)
		real(8), intent(in)					:: vr	! Wind speed (m/s)
		real(8), intent(in)					:: dir	! Wind direction (°)
		real(8), intent(in)					:: z0	! Aerodynamic roughness length (m)
		real(8), intent(in)					:: hmix	! Mixing height above ground (m)
		real(8), intent(in)					:: us	! Friction velocity (m/s)
		real(8), intent(in)					:: hlm	! Reciprocal of Obukhov length (1/m)
		real(8), dimension(:), intent(out)	:: u	! Wind component U (m/s)
		real(8), dimension(:), intent(out)	:: v	! Wind component V (m/s)
		integer								:: iRetCode
		
		! Locals
		integer	:: nz		! Number of levels
		real(8)	:: rot		! Coriolis coefficient (Hemisphere dependent)
		integer	:: n_PBL	! Index of PBL top (0 if lower height is above Zi)
		real(8)	:: a
		real(8)	:: b
		real(8)	:: a0
		real(8)	:: b0
		real(8)	:: a1
		real(8)	:: b1
		real(8)	:: h_mu
		real(8)	:: s_mu
		real(8)	:: usk
		real(8)	:: al0
		real(8)	:: zz
		real(8)	:: ur
		real(8)	:: cor
		real(8)	:: umix
		real(8)	:: vmix
		real(8)	:: velmix
		real(8)	:: dirmix
		real(8)	:: ang
		real(8)	:: uu
		real(8)	:: vv
		real(8)	:: velp
		real(8)	:: dirpp
		integer	:: i
		
		! Constants
		real(8), parameter	:: TO_RAD = atan(1.d0)*4.d0 / 180.d0
		real(8), parameter	:: K      = 0.4d0	! von Karman constant
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check critical parameters
		nz = size(z)
		if(nz <= 0) then
			iRetCode = 1
			return
		end if
		if(size(u) /= nz .or. size(v) /= nz) then
			iRetCode = 2
			return
		end if
		if(z0 <= 0.d0) then
			iRetCode = 3
			return
		end if
		if(vr <= 0.d0) then
			iRetCode = 4
			return
		end if
		if(dir < 0.d0 .or. dir >= 360.) then
			iRetCode = 5
			return
		end if
		if(nz > 1) then
			do i = 2, nz
				if(z(i) <= z(i-1)) then
					iRetCode = 6
					return
				end if
			end do
		end if
		
		! Compute Coriolis coefficient, given the hemisphere
		rot = 1.d0
		if(iglo == 0) rot = -1.d0

		! Find index of the PBL top
		if(minval(z) > hmix) then
			n_PBL = 0
		elseif(zr > hmix) then
			! Wind has been measured above Hmix: extend it vertically as it is
			u = -vr*sin(TO_RAD*dir)
			v = -vr*cos(TO_RAD*dir)
			return
		else
			n_PBL = nz
			do i = nz, 1, -1
				if(z(i) < hmix) then
					n_PBL = i
					exit
				end if
			end do
		end if
		! Post-condition: n_PBL is 0 if z(1) is above Hmix, or > 0

		! Estimate profile
		if(abs(hlm) < 1.d-3) then
		
			! Neutral
			a0 = 10.d0
			a1 = -5.5d0
			b0 =  4.0d0
			b1 = -4.5d0
			
		else
		
			! Stable or convective
			h_mu = 4000. * us * hlm
			s_mu = sqrt(abs(h_mu))
			
			if(hlm.GT.0.) then
			
				! Stable
				a0 = 10.d0
				a1 = -5.5d0 +  1.7647d0 * s_mu
				b0 =  4.0d0 + 10.20d0 * s_mu
				b1 = -4.5d0 -  7.65d0 * s_mu
				
			else
		
				! Convective
				a  = 1.d0 + 1.581d0 * s_mu
				b  = 1.d0 + 0.027d0 * s_mu
				a0 = 10.0d0 / a
				a1 = -5.5d0 / a
				b0 = -34.d0 + 38.0d0 / b
				b1 =  24.d0 - 28.5d0 / b
				
			end if
			
		end if

		!	Calcolo del vento a zr e confronto col dato misurato
		usk = us/K
		al0 = log(zr/z0)
		zz  = (zr-z0)/hmix
		ur  = usk*(al0+b0*zz+b1*zz*zz)
		cor = vr/ur

		! Estimate wind velocity at wind speed
		al0    = log(hmix/z0)
		umix   = usk*(al0+b0+b1)*cor
		vmix   = usk*(a0+a1)*cor
		
		! Translate wind vector velocity at Hmix into polar form
		velmix = sqrt(umix**2+vmix**2)
		if(abs(vmix) < 1.d-5) then
			if(umix > 0.d0) then
				dirmix = dir +  90.0d0*rot
			else
				dirmix = dir + 270.0d0*rot
			end if
		else
			dirmix = dir + atan2(vmix,umix)/TO_RAD*rot
		end if
		if(dirmix <   0.d0) dirmix = dirmix + 360.d0
		if(dirmix > 360.d0) dirmix = dirmix - 360.d0

		! In case the first z level is above the mixing height, extend it vertically
		! as it has been estimated at Hmix. Otherwise, construct the profile until
		! Hmix, then extend it vertically as it is
		if(n_PBL == 0) then
		
			! Vertical extension of Hmix estimated wind
			u = -velmix*sin(TO_RAD*dirmix)
			v = -velmix*cos(TO_RAD*dirmix)
			return
			
		else
		
			! Compute a real profile within the PBL
			do i = 1, n_PBL
				zz  = (z(i)-z0)/hmix
				al0 = log(z(i)/z0)
				uu  = usk*(al0+b0*zz+b1*zz*zz)*cor
				vv  = usk*(a0*zz+a1*zz*zz)*cor
				if(abs(vv) < 1.d-5) then
					if(uu > 0.d0) then
						ang=90.d0
					else
						ang=270.d0
					end if
				else
					ang = atan2(vv,uu) / TO_RAD
				end if
				velp  = sqrt(uu**2+vv**2)
				dirpp = dir + ang*rot
				if(dirpp .LT. 0.  ) dirpp = dirpp + 360.
				if(dirpp .GT. 360.) dirpp = dirpp - 360.
				u(i) = -velp*SIN(TO_RAD*dirpp)
				v(i) = -velp*COS(TO_RAD*dirpp)
			end do
			
			! Propagate Hmix values above the PBL
			if(n_PBL < nz) then
				u(n_PBL+1:) = -velmix*SIN(TO_RAD*dirmix)
				v(n_PBL+1:) = -velmix*COS(TO_RAD*dirmix)
			end if
		end if

	end function WindProfile
	

	! This is a very extensive refactoring of code by prof. Roberto Sozzi
	function TempProfile(z,z0,zr,Tr,gamma,hmix,Ts,us,hm,T) result(iRetCode)

		! Routine arguments
		real(8), dimension(:), intent(in)	:: z		! Heights above ground (m)
		real(8), intent(in)					:: z0		! Aerodynamic roughness length (m)
		real(8), intent(in)					:: zr		! Temperature measurement measurement height above ground (m)
		real(8), intent(in)					:: Tr		! Measured temperature (K)
		real(8), intent(in)					:: gamma	! Temperature lapse rate (above the PBL) (K/m)
		real(8), intent(in)					:: hmix		! Mixing height above ground (m)
		real(8), intent(in)					:: Ts		! Scale temperature (K)
		real(8), intent(in)					:: us		! Friction velocity (m/s)
		real(8), intent(in)					:: hm		! Reciprocal of Obukhov length (1/m)
		real(8), dimension(:), intent(out)	:: T		! Temperature (K)
		integer								:: iRetCode
		
		! Locals
		integer	:: n
		integer	:: i
		integer	:: itop
		integer	:: nzhm
		real(8)	:: smu
		real(8)	:: psi
		real(8)	:: Cfun
		real(8)	:: AA
		real(8)	:: Trif
		real(8)	:: zbase
		real(8)	:: Tbase
		real(8)	:: zbot
		real(8)	:: ztop
		real(8)	:: Ttop
		real(8)	:: DelT
		real(8)	:: we
		real(8)	:: RiE
		real(8)	:: Coe
		real(8)	:: DelZ
		real(8)	:: gz
		
		! Constants
		real(8), parameter	:: K = 0.4
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check critical parameters
		n = size(z)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		if(n /= size(T)) then
			iRetCode = 2
			return
		end if
		if(z0 <= 0.d0) then
			iRetCode = 3
			return
		end if
		if(n > 1) then
			do i = 2, n
				if(z(i) <= z(i-1)) then
					iRetCode = 4
					return
				end if
			end do
		end if

		! Find the PBL top
		if(minval(z) > hmix) then
			nzhm = 1
		else
			nzhm = n
			do i = 2, n
				if(z(i) > hmix) then
					nzhm = i - 1
					exit
				end if
			end do
		end if

		! Assign above-PBL profile, if requested
		if(nzhm == 1) then
			t(1) = tr
			do i = 2, n
				T(i) = tr + gamma*z(i)
			end do
			return
		end if

		! Some level is within-PBL: estimate the PBL profile
		smu	= hmix*hm
		if(smu > 0.d0) then
			psi = -17.d0 * (1.d0 - exp(-0.29d0*zr*hm))			! Businger, stable
		else
			psi = 2.d0*log((1.d0+sqrt(1.d0-16.d0*zr*hm))/2.d0)	! Businger, convective
		end if
		Cfun =  C_fun(smu)
		AA   = -Ts/K * (log(hmix/zr) + psi - Cfun)
		Trif =  Tr - AA

		! Estimate temperature profile up to PBL top
		do i = 1, nzhm
			if(smu > 0.d0) then
				psi = -17.d0 * (1.d0 - exp(-0.29d0*z(i)*hm))			! Businger, stable
			else
				psi = 2.d0*log((1.d0+sqrt(1.d0-16.d0*z(i)*hm))/2.d0)	! Businger, convective
			end if
			AA   = -Ts/K * (log(hmix/z(i)) + psi - Cfun)
			T(i) =  trif  + AA
		end do

		! Temperature profile above the PBL top
		if(smu >= 0.d0) then
			! Stable
			if(n > nzhm) then
				zbase = z(nzhm)
				do i = nzhm, n
					T(i) = T(nzhm) + gamma*(z(i) - zbase)
				end do
			end if
			return
		else
		
			! Convective
			psi  =  2.d0*log((1.d0+sqrt(1.d0-16.d0*z0*hm))/2.d0)	! Businger, convective
			Cfun =  C_fun(smu)
			AA   = -Ts/K * (log(hmix/z0) + psi - Cfun)
			Ttop =  Tr + AA
			DelT =  max(Ttop-T(NZHM), 0.01d0)
			we   =  hmix**2/(1.4*hmix-2./hm)
			we   =  (-Ts*us)/gamma/we
			RiE  = 9.81/Tr * DelT*hmix/we**2
			Coe  = 3.3/RiE**0.3333 + 0.2
			DelZ = Coe*hmix
			gz   = DelT/DelZ
			DelZ = DelZ/2.

			! Entrainment Layer Depth					
			ztop = hmix + Delz
			do i = nzhm, n
				if(z(i) > ztop) exit
			end do
			itop = i
			
			! Entrainment Layer Profile
			Tbase = T(NZHM)
			zbot  = z(NZHM)
			do i = nzhm + 1, itop
				T(i) = Tbase + 2.d0*gz*(z(i)-zbot)
			end do

			! Free Atmosphere Profile
			Tbase = T(itop)
			do i = itop + 1, n
				T(i) = Tbase + gz*(z(i)-ztop)						
			end do
		end if

	end function TempProfile
	
	
	! Horizontal wind components variance according to
	! Rotach, Gryning, Tassone, 1996.
	! This is a very extensive refactoring of code by prof. Roberto Sozzi
	function HorizontalWindVarProfile(z,us,ws,zi,su2,sv2) result(iRetCode)
	
		! Routine arguments
		real(8), dimension(:), intent(in)	:: z
		real(8), intent(in)					:: us
		real(8), intent(in)					:: ws
		real(8), intent(in)					:: zi
		real(8), dimension(:), intent(out)	:: su2
		real(8), dimension(:), intent(out)	:: sv2
		integer								:: iRetCode

		! Locals
		integer	:: iErrCode
		integer	:: i
		integer	:: n
		real(8)	:: us2
		real(8)	:: ws2
		real(8)	:: zz
		real(8)	:: s1
		real(8)	:: s2
		
		! Constants
		real(8), parameter	:: Sh2_min = 0.05d0
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check essential parameters
		n = size(z)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		if(size(su2) /= n .or. size(sv2) /= n) then
			iRetCode = 2
			return
		end if
		if(n > 1) then
			do i = 2, n
				if(z(i) <= z(i-1)) then
					iRetCode = 3
					return
				end if
			end do
		end if
		
		! Initialization
		us2 = us**2
		ws2 = ws**2

		! Main loop
		do i = 1, n

			! Normalize height toPBL depth
			zz = z(i)/zi
			if(zz <= 1.0d0) then
				! Within-PBL

				! Mechanical part of variance
				s1 = max((5.d0 - 4.d0*zz) * us2,0.d0)
				
				! Convective part of variance
				if(ws > 0.) then
					s2 = 0.4d0 * ws2
				else
					s2 = 0.d0
				end if
				
				! Combine mechanical and convective variances
				su2(i) = max((s1 + 1.33333*s2) , Sh2_min)
				sv2(i) = max((s1 +         s2) , Sh2_min)
				
			else
			
				su2(i) = Sh2_min
				sv2(i) = Sh2_min
				
			end if

		end do

	end function HorizontalWindVarProfile
	
	
	! Estimation of vertical wind component variance and its first derivative
	! Reference: Rotach, Gryning, Tassone (1996).
	! This is a very extensive refactoring of code by prof. Roberto Sozzi
	function VerticalWindVarProfile(z,us,ws,z0,zi,sw2,d_sw2) result(iRetCode)
	
		! Routine arguments
		real(8), dimension(:), intent(in)	:: z
		real(8), intent(in)					:: us
		real(8), intent(in)					:: ws
		real(8), intent(in)					:: z0
		real(8), intent(in)					:: zi
		real(8), dimension(:), intent(out)	:: sw2
		real(8), dimension(:), intent(out)	:: d_sw2
		integer								:: iRetCode
		
		! Locals
		integer	:: iErrCode
		integer	:: n
		integer	:: i
		real(8)	:: us2
		real(8)	:: ws2
		real(8)	:: es1
		real(8)	:: es2
		real(8)	:: zz
		real(8)	:: sw2m
		real(8)	:: sw2c
		real(8)	:: ezz

		! Constants
		real(8), parameter	:: Sw2_min = 0.01d0

		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check essential parameters
		n = size(z)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		if(size(sw2) /= n .or. size(d_sw2) /= n) then
			iRetCode = 2
			return
		end if
		if(n > 1) then
			do i = 2, n
				if(z(i) <= z(i-1)) then
					iRetCode = 3
					return
				end if
			end do
		end if
		
		! Initialization
		us2 = us**2
		ws2 = ws**2
		es1 = 2.d0/3.d0
		es2 = 1.d0/3.d0

		! Main loop: compute the profiles desired
		do i = 1, n
	
			! Normalize altitude to PBL height
			zz = z(i)/zi
			if(zz <= 1.d0) then
				! Within PBL
				
				! Mechanical variance portion
				sw2m = max((1.7d0 - zz) * us2, 0.d0)
				
				! Convective variance portion
				if(zz > 100.d0) then
	                ezz = 0.d0
				else
					ezz = exp(-2.d0*zz)
				end if
				if(ws > 0.d0) then
					sw2c = 1.5d0 * zz**es1 * ezz * ws2 
				else
					sw2c = 0.d0
				end if
				
				! Combine mechanical and convective variances
				sw2(i) = max(sw2m + sw2c, Sw2_min)

				! First derivative of variance
				if(z(i) > z0) then
					d_sw2(i) = ((1.d0-3.d0*zz)/(zz**es2) *ezz*ws2 - us2) / zi
				else
					d_sw2(i) = 0.d0
				end if
				
			else
				! Beyond PBL
				sw2(i)   = Sw2_min
				d_sw2(i) = 0.
			end if
			
		end do
		
	end function VerticalWindVarProfile
	
	! References: Rotach, Gryning, Tassone (1996) e Ryall e Maryon (1998)
	! This is a very extensive refactoring of code by prof. Roberto Sozzi
	function TKEDissipationProfile(z,us,ws,z0,zi,eps) result(iRetCode)
	
		! Routine arguments
		real(8), dimension(:), intent(in)	:: z
		real(8), intent(in)					:: us
		real(8), intent(in)					:: ws
		real(8), intent(in)					:: z0
		real(8), intent(in)					:: zi
		real(8), dimension(:), intent(out)	:: eps
		integer								:: iRetCode
		
		! Locals
		integer	:: iErrCode
		integer	:: n
		integer	:: i
		real(8)	:: us3
		real(8)	:: ws3
		real(8)	:: es1
		real(8)	:: zz
		real(8)	:: epsm
		real(8)	:: epsc

		! Constants
		real(8), parameter	:: eps_min = 1.d-4
		real(8), parameter	:: K = 0.4d0
	
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Check essential parameters
		n = size(z)
		if(n <= 0) then
			iRetCode = 1
			return
		end if
		if(size(eps) /= n) then
			iRetCode = 2
			return
		end if
		if(n > 1) then
			do i = 2, n
				if(z(i) <= z(i-1)) then
					iRetCode = 3
					return
				end if
			end do
		end if

		! Initialization
		us3 = us**3
		ws3 = ws**3
		es1 = 1.d0/3.d0

		! Main loop: estimate TKE dissipation profile
		do i = 1, n

			! Normalize altitude to PBL height
			zz = z(i)/zi
			if(zz <= 1.d0) then
				! Within pbl
				if(z(i) <= z0) then
					epsm = eps_min
				else
					epsm = us3 / (K*z(i)) * (1.d0 - 0.8d0*zz)
				end if
				if(ws > 0.d0) then
					epsc   = (1.5d0 - 1.2d0*zz**es1) * ws3 / zi
					eps(i) = max(epsm + epsc, eps_min)
				else
					eps(i) = max(epsm, eps_min)
				end if
			else
				! Above PBL
				eps(i) = eps_min
			end if

		end do
		
	end function TKEDissipationProfile
	
	
	! Reference: Degrazia e Anfossi (1998)
	function KolmogorovConstants(ws,C0u,C0v,C0w) result(iRetCode)
	
		! Routine arguments
		real(8), intent(in)		:: ws
		real(8), intent(out)	:: C0u
		real(8), intent(out)	:: C0v
		real(8), intent(out)	:: C0w
		integer					:: iRetCode
		
		! Locals
		real(8)	:: Coe
		
		! Constants
		real(8), parameter	:: PG2K  = 0.541d0			!(2 pg k)**-2/3
		real(8), parameter	:: K     = 0.4d0
		
		! Assume success (will falsify on failure)
		iRetCode = 0
		
		! Compute estimates based on convective and stable conditions
		if(ws > 0.d0) then
			! Convective
			Coe = 8.d0*K / (1.d0*0.55d0)
			C0u = Coe * (1.96d0 * 0.5d0*PG2K)**1.5d0
			C0v = Coe * (1.96d0 * 0.66667d0*PG2K)**1.5d0
			C0w = C0v
		else
			! Stable
			Coe = 8.*K / (0.64d0 * 0.55d0)
			C0u = Coe * (2.33d0 * 0.5d0*PG2K)**1.5d0
			C0v = Coe * (1.96d0 * 0.66667d0*PG2K)**1.5d0
			C0w = C0v
		end if

	end function KolmogorovConstants

	! *************
	! * Internals *
	! *************

	! From Yamada's (1976) correlations.
	function C_fun(smu) result(Cf)
	
		! Routine arguments
		real(8), intent(in)	:: smu	! hmix/L (unitless)
		real(8)				:: Cf
		
		! Locals
		! --none--
		
		if(smu < 0.d0) then
			Cf = 12.d0-8.335d0/(1.d0-0.03106d0*smu)**0.3333d0
		else
			if(smu > 18.d0) then
				Cf = -4.32d0*sqrt(smu-11.21d0)
			else
				Cf = 3.665d0-0.829d0*smu
			end if
		end if
		
	end function C_fun

end module pbl_simil


! pbl_depth  : Fortran module, providing support to the estimation of
!              mixing height and other quantities in the full depth of
!              the Planetary Boundary Layer.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_depth

    use pbl_base
    use pbl_wind
    use pbl_simil
    use pbl_time
    use pbl_thermo

    implicit none

    private

    ! Public interface
    public	:: EstimateZi
    public	:: LapseRateSpec

    ! Data types

    type LapseRateSpec
    	real(8)	:: A
    	real(8)	:: B
    	real(8)	:: C
    contains
    	procedure	:: setDefault	=> lrSetDefault
    	procedure	:: getLapseRate	=> lrGetLapseRate
    end type LapseRateSpec

contains

	function EstimateZi(rvTimeStamp, iZone, rLat, rLon, iDeltaTime, rvTemp, rvUstar, rvH0, rvN, nStep, tLrate, rvZi) result(iRetCode)

		! Routine arguments
		real(8), dimension(:), allocatable, intent(in)				:: rvTimeStamp
		integer, intent(in)											:: iZone
		real, intent(in)											:: rLat
		real, intent(in)											:: rLon
		integer, intent(in)											:: iDeltaTime
		real(8), dimension(:), allocatable, intent(in)				:: rvTemp
		real(8), dimension(:), allocatable, intent(in)				:: rvUstar
		real(8), dimension(:), allocatable, intent(in)				:: rvH0
		real(8), dimension(:), allocatable, intent(in), optional	:: rvN
		integer, intent(in), optional								:: nStep
		type(LapseRateSpec), intent(in), optional					:: tLrate
		real(8), dimension(:), allocatable, intent(out)				:: rvZi
		integer														:: iRetCode

		! Locals
		integer								:: iErrCode
		integer								:: i
		real, dimension(2)					:: rvSunRiseSet
		type(DateTime)						:: tStamp
		real(8)								:: rSunRise
		real(8)								:: rSunSet
		real(8)								:: rHour
		real(8)								:: rN
		real(8)								:: rTa
		real(8)								:: rRc
		real(8)								:: rZiMec
		real(8)								:: rZiConv
		real(8)								:: rWprimeThetaprime
		real(8)								:: rL
		integer								:: n_step
		integer, dimension(5)				:: ivVectorLength
		integer, dimension(5)				:: ivValidNum

		! Constants
		real(8), parameter	:: k = 0.4d0
		real(8), parameter	:: g = 9.81d0

		! Assume success (will falsify on failure)
		iRetCode = 0

		! Check something can be made
		if( &
			.not.allocated(rvTimeStamp) .or. &
			.not.allocated(rvTemp) .or. &
			.not.allocated(rvUstar) .or. &
			.not.allocated(rvH0) &
		) then
			iRetCode = 1
			return
		end if
		if(present(rvN)) then
			if(.not.allocated(rvTimeStamp)) then
				iRetCode = 1
				return
			end if
		end if
		ivVectorLength(1) = size(rvTimeStamp)
		ivVectorLength(2) = size(rvTemp)
		ivVectorLength(3) = size(rvUstar)
		ivVectorLength(4) = size(rvH0)
		ivVectorLength(5) = size(rvTimeStamp)
		if(present(rvN)) ivVectorLength(5) = size(rvN)
		if(minval(ivVectorLength) <= 0) then
			iRetCode = 2
			return
		end if
		if(minval(ivVectorLength) /= maxval(ivVectorLength)) then
			iRetCode = 3
			return
		end if
		if(present(nStep)) then
			if(nStep <= 0) then
				iRetCode = 4
				return
			end if
			n_step = nStep
		else
			n_step = 60
		end if
		ivValidNum(1) = count(.valid.rvTimeStamp)
		ivValidNum(2) = count(.valid.rvTemp)
		ivValidNum(3) = count(.valid.rvUstar)
		ivValidNum(4) = count(.valid.rvH0)
		ivValidNum(5) = count(.valid.rvTimeStamp)
		if(present(rvN)) ivValidNum(5) = count(.valid.rvN)
		if(minval(ivValidNum) <= 0) then
			iRetCode = 5
			return
		end if

		! Reserve workspace
		if(allocated(rvZi)) deallocate(rvZi)
		allocate(rvZi(size(rvTimeStamp)))

		! Main loop: process mixing heights
    	do i = 1, size(rvTimeStamp)

    		if(.invalid.rvTimeStamp(i)) then
    			rvZi(i) = NaN_8
    			cycle
    		end if

			! Get time stamp at official value (to help tracking events in data files;
			! true time stamp at mid of averagin interval will be computed immediately after)
			iErrCode = tStamp % fromEpoch(rvTimeStamp(i) + iDeltaTime / 2.d0)
			if(iErrCode /= 0) then
    			rvZi(i) = NaN_8
    			cycle
			end if
			if(.not.(.sensible. tStamp)) then
    			rvZi(i) = NaN_8
    			cycle
			end if

			! Get time stamp at *mid* of averaging interval
			rHour = tStamp % iHour + tStamp % iMinute / 60.0d0 + tStamp % rSecond / 3600.0d0

			! Get astronomical indicators
			rvSunRiseSet = SunRiseSunSet(tStamp % iYear, tStamp % iMonth, tStamp % iDay, rLat, rLon, iZone)
			rSunRise = rvSunRiseSet(1)
			rSunSet  = rvSunRiseSet(2)

			! Estimate mixing height
			rTa    = rvTemp(i) + 273.15d0
			rRc    = RhoCp(rTa)
			rZiMec = 1330.*rvUstar(i)
			if(rHour > rSunRise .and. rHour < rSunSet) then
				rZiConv = MAX(rZiConv, 0.d0)
				if(present(tLrate)) then
					rZiConv = ConvectiveZi(dble(iDeltaTime),rvH0(i),rvUstar(i),rTa,rRc,rZiConv,n_step,tLrate)
				else
					rZiConv = ConvectiveZi(dble(iDeltaTime),rvH0(i),rvUstar(i),rTa,rRc,rZiConv,n_step)
				end if
				rvZi(i) = max(rZiMec, rZiConv)
			else
				rZiConv = 0.
				rWprimeThetaprime = rvH0(i) / rRc
				rL = - rvUstar(i)**3 * rTa / (k*g*rWprimeThetaprime)
				if(present(rvN)) then
					rN = rvN(i)
				else
					rN = 0.012
				end if
				rvZi(i) = StableZi( &
					rLat, &
					rvTemp(i), &
					rvH0(i), &
					rvUstar(i), &
					rL, &
					rN &
				)
			end if

		end do

	end function EstimateZi

	! *********************
	! * Internal routines *
	! *********************

	function ConvectiveZi(dtime,H0,us,Temp,rc,hold,n_step, tLrate) result(hmix)

		! Routine arguments
		real(8), intent(in)							:: dtime		! Time step (s)
		real(8), intent(in)							:: H0			! Turbulent sensible heat flux (W/m2)
		real(8), intent(in)							:: us			! Friction velocity (m/s)
		real(8), intent(in)							:: Temp			! Temperature (°C)
		real(8), intent(in)							:: rc			! RhoCp
		real(8), intent(in)							:: hold			! Mixing height on previous time step (m)
		integer, intent(in)							:: n_step		! Number of sub-steps within a whole step
		type(LapseRateSpec), intent(in), optional	:: tLrate		! If specified, lapse rate is computed from here instead of assumed as constant (default behavior)
		real(8)										:: hmix			! Mixing height past current time step (m)

		! Locals
		real(8)		:: dt
		real(8)		:: Ta
		real(8)		:: gamma
		real(8)		:: tempZi
		real(8)		:: hk1
		real(8)		:: hk2
		real(8)		:: hk3
		real(8)		:: hk4
		integer		:: i

		! Check something can be made
		if(n_step <= 0) then
			hmix = NaN_8
			return
		end if

		! Initialize
		Hmix = NaN_8
		dt   = dtime/n_step
		if(.invalid.rc) return
		Ta = Temp + 273.15d0

		! Runge-Kutta step
		if(present(tLrate)) then
			gamma = tLrate % getLapseRate(hold)
		else
			gamma = 0.005d0
		end if
		tempZi  = hold
		do i=1,n_step
			hk1  = dt * GryningBatchvarovaStep(rc,Ta,gamma,us,H0,tempZi)
			hk2  = dt * GryningBatchvarovaStep(rc,Ta,gamma,us,H0,tempZi+hk1/2.d0)
			hk3  = dt * GryningBatchvarovaStep(rc,Ta,gamma,us,H0,tempZi+hk2/2.d0)
			hk4  = dt * GryningBatchvarovaStep(rc,Ta,gamma,us,H0,tempZi+hk3/2.d0)
			tempZi  = tempZi + (hk1+2.d0*(hk2+hk3)+hk4)/6.d0
			if(present(tLrate)) then
				gamma = tLrate % getLapseRate(tempZi)
			else
				gamma = 0.005d0
			end if
		end do
		Hmix = tempZi

	end function ConvectiveZi


	function GryningBatchvarovaStep(rc,Tm,gg,us,h0,hm) result(F)

		! Routine arguments
		real(8), intent(in)	:: rc
		real(8), intent(in)	:: Tm
		real(8), intent(in)	:: gg
		real(8), intent(in)	:: us
		real(8), intent(in)	:: h0
		real(8), intent(in)	:: hm
		real(8)				:: F

		! Locals
		real(8)	:: hL
		real(8)	:: cost
		real(8)	:: f1
		real(8)	:: f2

		! Constants
		real(8), parameter	:: hk = 0.4d0
		real(8), parameter	:: g  = 9.81d0
		real(8), parameter	:: A  = 0.2d0
		real(8), parameter	:: B  = 2.5d0
		real(8), parameter	:: C  = 8.0d0

		! Compute the desired quantity
		hL   = -rc*Tm*us*us*us/(hk*g*h0)
		cost = B*hk*hL
		f1   = (1.+2.*A)*hm-2.*cost
		f2   = gg*g*((1.+A)*hm-cost)
		F    = hm*hm/f1 + C*us*us*Tm/f2
		F    = h0/(rc*gg*F)

	end function GryningBatchvarovaStep


	function StableZi(Lat, Temp, H0, Ustar, L, N) result(Zi)

		! Routine arguments
		real, intent(in)	:: Lat		! Latitude (degrees)
		real(8), intent(in)	:: Temp		! Air temperature (°C)
		real(8), intent(in)	:: H0		! Turbulent sensible heat flux (W/m2)
		real(8), intent(in)	:: Ustar	! Friction velocity (m/s)
		real(8), intent(in)	:: L		! Obukhov length (m)
		real(8), intent(in)	:: N		! Brunt-Vaisala frequency (Hz)
		real(8)				:: Zi

		! Locals
		real(8)				:: rLat
		real(8)				:: f
		real(8)				:: Ta
		real(8)				:: a
		real(8)				:: b1
		real(8)				:: b2
		real(8)				:: b3
		real(8)				:: b
		real(8)				:: wt
		real(8)				:: rc

		! Constants
		real(8), parameter	:: g = 9.807d0

		! Check something is to be done
		if(L < 1.e-5 .or. Ustar < 1.e-5 .or. Temp < -40.0) then
			Zi = 1330.0 * Ustar		! Degrade to purely mechanical rough estimate
			return
		end if
		! From now on, strong stability is guaranteed

		! Compute Coriolis parameter
		rLat = Lat * 3.14159265358979d0 / 180.d0
		f    = 2.d0*7.29d-5*SIN(rLat)

		! Compute temperature in K
		Ta = Temp + 273.15d0

		! Compute w't'
		rc = 1305.d0 * 273.16d0/Ta
		wt = H0 / rc

		! Compute Zilitinkevich non-advective function parts
		a  = (f/(0.5d0*Ustar))**2
		b1 = 0.1d0 / L
		b2 = N / (26.d0*Ustar)
		b3 = SQRT(ABS(g*f*wt/Ta)) / (1.7d0*Ustar)
		b  = b1 + b2 + b3

		! Compute stable estimate of mixing height
		Zi = (SQRT(4.d0*a + b**2) - b)/(2.d0*a)

		! Accept only within 100% difference from purely mechanical approx
		if(Zi > 2.0*1330.0*Ustar .or. Zi < 0.5*1330.0*Ustar) then
			Zi = 1330.0*Ustar
		else
			Zi = MAX(Zi, 1330.0*Ustar)
		end if

	end function StableZi


	subroutine lrSetDefault(this)

		! Routine arguments
		class(LapseRateSpec), intent(out)	:: this

		! Locals
		! --none--

		! Assign default values (from, I guess, Mexico City campaign, circa 1998)
		this % A = 3.d0
		this % B = 1.98d-3
		this % C = 2.27d-6

	end subroutine lrSetDefault


	function lrGetLapseRate(this, z) result(gamma)

		! Routine arguments
		class(LapseRateSpec), intent(in)	:: this
		real(8), intent(in)					:: z
		real(8)								:: gamma

		! Locals
		! --none--

		! Evaluate lapse rate
		if(z > 0.0) then
			gamma = this % A / (z + 1.d0) - this % B + this % C * z
		else
			gamma = this % A - this % B
		end if

	end function lrGetLapseRate

end module pbl_depth


! pbl_evtrn - Fortran module, containing computations pertaining to
!             Planetary Boundary Layer (PBL) quantities, encompassing
! evapotranspiration and related quantities.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_evtrn

	use pbl_base
	use pbl_time
	use pbl_thermo

	implicit none
	
	private
	
	! Public interface
	! 1. Evapotranspiration and related quantities
	public	:: ColtureLAI
	public	:: AerodynamicResistance
	public	:: Evapotranspiration
	
contains
	
	! Estimation of leaf area index (LAI) based on vegetation height and type,
	! for coltures, as from the ASCE Evapotranspiration Standard Equation.
	function ColtureLAI(rVegetationHeight, iColtureType) result(rLAI)

		implicit none

		! Routine arguments
		real, intent(in)	:: rVegetationHeight	! (m)
		integer, intent(in)	:: iColtureType			! LAI_GRASS, LAI_ALFALFA
		real				:: rLAI

		! Locals
		! -none-

		! Compute the information desired
		select case(iColtureType)
		case(LAI_GRASS)
			rLAI = 24.0 * rVegetationHeight
		case(LAI_ALFALFA)
			rLAI = 5.5 + 1.5 * LOG(rVegetationHeight)
		case default
			rLAI = NaN
		end select

	end function ColtureLAI


	function AerodynamicResistance(zw, zh, u, h) result(ra)

		implicit none

		! Routine arguments
		real, intent(in)	:: zw	! Height above ground at which wind is measured (m)
		real, intent(in)	:: zh	! Height above ground at which temperature/humidity are measured (m)
		real, intent(in)	:: u	! Wind speed (m/s)
		real, intent(in)	:: h	! Vegetation height (h)
		real				:: ra	! Aerodynamic resistance

		! Locals
		real	:: d	! Displacement height
		real	:: z0m	! Roughness length governing momentum transfer (m)
		real	:: z0h	! Roughness length governing heat transfer (m)

		! Constant
		real, parameter	:: k = 0.41	! von Karman constant

		! Compute the information desired
		if(u > 0.) then
			d = 0.67 * h
			z0m = 0.123 * h
			z0h = 0.0123 * h
			ra = LOG((zw-d)/z0m) * LOG((zh-d)/z0h) / (k**2 * u)
		else
			ra = NaN
		end if

	end function AerodynamicResistance


	function Evapotranspiration(Pres, Temp, Vel, Rn, G, es, ea, Zr, vegType) result(ET)

		implicit none

		! Routine arguments
		real, intent(in)	:: Pres		! Air pressure (hPa)
		real, intent(in)	:: Temp		! Air temperature (°C)
		real, intent(in)	:: Vel		! Wind speed (m / s)
		real, intent(in)	:: Rn		! Net radiation (W / m2)
		real, intent(in)	:: G		! Ground heat flux (W / m2)
		real, intent(in)	:: es		! Saturation vapor pressure (hPa)
		real, intent(in)	:: ea		! Water vapor pressure (hPa)
		real, intent(in)	:: Zr		! Anemometer measurement height (m above ground)
		integer, intent(in)	:: vegType	! Vegetation type (ASCE_GRASS, ASCE_ALFALFA)
		real				:: ET		! Evapotranspiration (mm/h)

		! Locals
		real	:: Delta	! Slope (first derivative) of saturation vapor pressure relation
		real	:: gam		! Psychrometric constant (kPa / °C)
		real	:: Vel2		! Wind speed at 2 m above ground
		real	:: h		! Vegetation height (m)
		real	:: d		! Displacement height (m)
		real	:: z0		! Aerodynamic roughness length (m)
		real	:: cd
		real	:: cn

		! Estimate coefficients based on reference vegetation type
		select case(vegType)
		case(ASCE_GRASS)
			h  =  0.12
			cn = 37.0
			if(Rn > 0.) then
				cd = 0.24
			else
				cd = 0.96
			end if
		case(ASCE_ALFALFA)
			h  =  0.50
			cn = 66.0
			if(Rn > 0.) then
				cd = 0.25
			else
				cd = 1.70
			end if
		case default
			ET = NaN
			return
		end select

		! Compute evapotranspiration
		Delta = 2503.0 * EXP(17.27*Temp/(Temp + 237.3)) / (Temp + 237.3)**2
		gam   = 0.0000665*Pres
		d     = 0.67 * h
		z0    = 0.123 * h
		Vel2  = Vel * LOG((2.0 - d)/z0) / LOG((Zr - d) / z0)
		ET = (&
			(0.408*Delta*(Rn-G)*3600.0/1.e6 + gam*cn/(Temp + 273.0)*Vel2*0.1*(es-ea)) / &
			(Delta + gam*(1.0 - cd*Vel2)) &
		)

	end function Evapotranspiration
	
end module pbl_evtrn


! pbl_met - Fortran module, collecting all other modules and providing
!           an unique access point to pbl_met library.
!
! This module is part of the pbl_met library.
!
! This is open-source code, covered by the lGPL 3.0 license.
!
! Author(s): Patrizia Favaron
!
module pbl_met

	! Collect all sub-libraries

	use pbl_base
	use pbl_depth
	use pbl_evtrn
	use pbl_simil
	use pbl_stat
	use pbl_thermo
	use pbl_time
	use pbl_wind
	
	implicit none
	
end module pbl_met
