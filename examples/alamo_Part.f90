module Particles
	
	use pbl_met
	use Configuration
	
	implicit none

	type Particle
		real(8)	:: EmissionTime
		real(8)	:: Xp, Yp, Zp	! Position
		real(8)	:: up, vp, wp	! Velocity
		real(8)	:: Qp, Tp		! Mass, temperature
		real(8)	:: sh, sz		! Horizontal, vertical sigmas for Gaussian kernel
	contains
		procedure	:: Emit => parEmit
	end type Particle

	type ParticlePool
		type(Particle), dimension(:), allocatable	:: tvPart
		integer										:: next
	contains
		procedure	:: Emit => parEmit
	end type ParticlePool
	
contains

end module Particles
