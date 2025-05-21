"use client";

import { useQuery } from '@tanstack/react-query';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Database } from '@/types/supabase'; // Assuming this path is correct

type Person = Database['public']['Tables']['people']['Row'];

// Define the shape of the data returned by the Supabase query
interface GetPeopleResponse {
  data: Person[] | null;
  error: any; // Or a more specific Supabase error type
  count: number | null; // If you fetch count separately or if Supabase returns it
}

// The actual fetching function
const fetchPeople = async (page = 1, pageSize = 10): Promise<GetPeopleResponse> => {
  const supabase = createClientComponentClient<Database>();
  const start = (page - 1) * pageSize;

  const { data, error, count } = await supabase
    .from('people')
    .select('*', { count: 'exact' }) // Request count
    .range(start, start + pageSize - 1)
    .order('last_name', { ascending: true });

  // Ensure the response matches GetPeopleResponse structure
  return { data, error, count };
};

// The custom hook
export const useGetPeople = (page = 1, pageSize = 10) => {
  return useQuery<GetPeopleResponse, Error>({
    queryKey: ['people', page, pageSize], // Query key includes page and pageSize for unique caching
    queryFn: () => fetchPeople(page, pageSize),
    // keepPreviousData: true, // Optional: useful for pagination to keep showing old data while new data loads
  });
};
