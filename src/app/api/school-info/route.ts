import { NextRequest, NextResponse } from 'next/server';
import { getConnection } from '@/lib/db';
import { getSchoolInfo } from '@/lib/schoolConfig';


export async function GET(req: NextRequest) {
  try {
    // Get school info from centralized configuration (single source of truth)
    const schoolInfo = getSchoolInfo();
    
    if (schoolInfo) {
      return NextResponse.json({
        success: true,
        data: {
          school_name: schoolInfo.name || 'Ibun Baz Girls Secondary School',
          school_address: schoolInfo.address || 'Busei, Iganga along Iganga-Tororo highway',
          school_contact: schoolInfo.contact?.phone || '+256 700 123 456',
          school_email: schoolInfo.contact?.email || 'info@ibunbaz.ac.ug',
        }
      });
    }

    // Return default values if config unavailable
    return NextResponse.json({
      success: true,
      data: {
        school_name: 'Ibun Baz Girls Secondary School',
        school_address: 'Busei, Iganga along Iganga-Tororo highway',
        school_contact: '+256 700 123 456',
        school_email: 'info@ibunbaz.ac.ug',
      }
    });
  } catch (error: any) {
    console.error('Error fetching school info:', error);
    return NextResponse.json({
      success: false,
      error: 'Failed to fetch school info',
      data: {
        school_name: 'Ibun Baz Girls Secondary School',
        school_address: 'Busei, Iganga along Iganga-Tororo highway',
        school_contact: '+256 700 123 456',
        school_email: 'info@ibunbaz.ac.ug',
      }
    });
  }
}
