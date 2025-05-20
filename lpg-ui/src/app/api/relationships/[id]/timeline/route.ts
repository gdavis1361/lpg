// src/app/api/relationships/[id]/timeline/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerActionClient } from '@supabase/auth-helpers-nextjs'; // For Route Handlers
import { cookies } from 'next/headers'; // For Route Handlers to access cookies

// Define a type for the timeline event structure from the database view
// This should ideally match the columns in your 'relationship_pair_timeline' view
interface TimelineEvent {
  relationship_id: string;
  from_person_id: string;
  from_person_name: string;
  to_person_id: string;
  to_person_name: string;
  relationship_type_name: string;
  event_type: string;
  event_date: string; // Assuming TIMESTAMPTZ comes as string
  event_title: string;
  event_description: string | null;
  event_primary_person_id: string;
  milestone_id: string | null;
  source_table_id: string;
  source_table_name: string;
  event_record_created_at: string; // Assuming TIMESTAMPTZ comes as string
}

// Define a type for the grouped timeline structure
interface GroupedTimeline {
  [monthYear: string]: TimelineEvent[];
}

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  // The 'id' parameter from the URL (relationship_id)
  const relationshipId = params.id;

  if (!relationshipId) {
    return NextResponse.json({ error: 'Relationship ID is required' }, { status: 400 });
  }

  // Create Supabase client for Route Handler
  // Note: For Route Handlers, you typically use `createServerActionClient` or `createServerComponentClient`
  // depending on the context. Since this is a GET request, `createServerActionClient` is suitable.
  // Ensure your Supabase client setup is correct for Route Handlers.
  const supabase = createServerActionClient({ cookies });

  // Check if user is authenticated
  const { data: { session }, error: sessionError } = await supabase.auth.getSession();

  if (sessionError) {
    console.error('Error getting session:', sessionError);
    return NextResponse.json({ error: 'Failed to get session' }, { status: 500 });
  }
  
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  // Fetch timeline events from the 'relationship_pair_timeline' view
  const { data, error: fetchError } = await supabase
    .from('relationship_pair_timeline') // Ensure this view name is correct
    .select('*')
    .eq('relationship_id', relationshipId)
    .order('event_date', { ascending: false })
    .order('event_record_created_at', { ascending: false }); // Secondary sort for events on same day
    
  if (fetchError) {
    console.error('Timeline fetch error:', fetchError);
    return NextResponse.json({ error: 'Failed to fetch timeline data', details: fetchError.message }, { status: 500 });
  }
  
  if (!data) {
    return NextResponse.json({ timeline: {} }, { status: 200 }); // No data found, return empty object
  }

  // Group events by month and year for timeline display
  const groupedEvents = data.reduce((acc: GroupedTimeline, event: TimelineEvent) => {
    try {
      const date = new Date(event.event_date);
      // Ensure date is valid before formatting
      if (isNaN(date.getTime())) {
        console.warn(`Invalid event_date encountered: ${event.event_date} for event_unique_id: ${event.source_table_id}`);
        // Skip this event or handle as 'Unknown Date'
        const monthYear = 'Unknown Date';
        if (!acc[monthYear]) {
          acc[monthYear] = [];
        }
        acc[monthYear].push(event);
        return acc;
      }
      const monthYear = `${date.toLocaleString('default', { month: 'long' })} ${date.getFullYear()}`;
      
      if (!acc[monthYear]) {
        acc[monthYear] = [];
      }
      acc[monthYear].push(event);
    } catch (e) {
      console.error(`Error processing event date: ${event.event_date}`, e);
      // Optionally, group events with invalid dates under a special key
      const monthYear = 'Date Processing Error';
      if (!acc[monthYear]) {
        acc[monthYear] = [];
      }
      acc[monthYear].push(event);
    }
    return acc;
  }, {});
  
  return NextResponse.json({ timeline: groupedEvents }, { status: 200 });
}

// To ensure this route is treated as dynamic and not statically rendered at build time
export const dynamic = 'force-dynamic';
