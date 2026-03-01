import { NextRequest, NextResponse } from 'next/server';
import { getSchoolInfo } from '@/lib/schoolConfig';

/**
 * GET /api/school-config
 * Returns school configuration information
 * This is the single source of truth for school details across the system
 */
export async function GET(request: NextRequest) {
  try {
    const schoolInfo = getSchoolInfo();
    
    return NextResponse.json({
      success: true,
      school: schoolInfo,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('[API] School config error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to load school configuration',
        message: error.message,
      },
      { status: 500 }
    );
  }
}

/**
 * POST /api/school-config
 * Admin endpoint to update school configuration
 * Note: In production, this should be protected with authentication
 */
export async function POST(request: NextRequest) {
  try {
    // In production, verify admin authentication here
    const body = await request.json();
    
    // For now, just acknowledge the request
    // In production, you would write the new config to school-config.json
    console.log('[API] School config update request (not implemented):', body);
    
    return NextResponse.json({
      success: true,
      message: 'School configuration update functionality coming soon',
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('[API] School config update error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to update school configuration',
        message: error.message,
      },
      { status: 500 }
    );
  }
}
