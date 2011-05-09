
def idx_max_sq idx
	sqrt = (Math.sqrt idx.abs).to_i
	return sqrt * sqrt
end

def idx_ray idx
	sqrt = (Math.sqrt idx.abs).to_i
	return ( (sqrt + 1) / 2 )
end

def idx_diameter idx
	return (Math.sqrt idx.abs).to_i
end

def idx_prevsurf idx
	diam = idx_diameter idx
	return diam * diam
end

def idx_offset idx
	prev_surf = idx_prevsurf idx
	ray = idx_ray idx
	offset = ( idx + ray ) - ( prev_surf )
	puts "offset(%d) : surf=%s ray=%s" % [idx, prev_surf, ray]

	return offset
end

if (File.expand_path $0) == (File.expand_path __FILE__) then
	require "test/unit"

	class TestZone < Test::Unit::TestCase                                                                          
		def test_idx_max_sq
			assert_equal( 0, idx_max_sq(0) )
			assert_equal( 1, idx_max_sq(1) )
			assert_equal( 1, idx_max_sq(2) )
			assert_equal( 1, idx_max_sq(3) )
			assert_equal( 4, idx_max_sq(4) )
			assert_equal( 4, idx_max_sq(5) )
			assert_equal( 16, idx_max_sq(23) )
			assert_equal( 25, idx_max_sq(26) )
		end

		def test_idx_ray
			# y=0
			assert_equal( 0, idx_ray(0) )
			assert_equal( 1, idx_ray(1) )
			assert_equal( 2, idx_ray(10) )
			assert_equal( 3, idx_ray(27) )

			# y=1
			assert_equal( 1, idx_ray(2) )
			assert_equal( 1, idx_ray(3) )
			assert_equal( 1, idx_ray(4) )
			assert_equal( 2, idx_ray(11) )
			assert_equal( 2, idx_ray(12) )
			assert_equal( 2, idx_ray(13) )
		end

		def test_idx_offset
			[0,1,2,3,8,9,10,11,12,27].each do |x|
				puts "%s => %s" % [x, idx_offset(x)]
			end
			assert_equal( 0, idx_offset(1) )
			assert_equal( 0, idx_offset(10) )
			assert_equal( 0, idx_offset(27) )

			#
			assert_equal( 1, idx_offset(2) )
			assert_equal( 2, idx_offset(3) )
			assert_equal( 7, idx_offset(8) )
			assert_equal( 8, idx_offset(9) )
		end
	end
end

