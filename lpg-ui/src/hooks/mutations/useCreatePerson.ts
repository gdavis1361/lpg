"use client";

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Database } from '@/types/supabase'; // Assuming this path is correct

type PersonInsert = Database['public']['Tables']['people']['Insert'];
type Person = Database['public']['Tables']['people']['Row'];

// Define the shape of the data returned by the Supabase mutation
interface CreatePersonResponse {
  data: Person | null;
  error: any; // Or a more specific Supabase error type
}

// The actual mutation function
const createPerson = async (personData: PersonInsert): Promise<CreatePersonResponse> => {
  const supabase = createClientComponentClient<Database>();

  const { data, error } = await supabase
    .from('people')
    .insert(personData)
    .select()
    .single(); // Assuming you want the created record back

  return { data, error };
};

// The custom mutation hook
export const useCreatePerson = () => {
  const queryClient = useQueryClient();

  return useMutation<CreatePersonResponse, Error, PersonInsert>({
    mutationFn: createPerson,
    onSuccess: (data) => {
      // Invalidate and refetch 'people' queries to reflect the new person
      // This is a common pattern for cache invalidation after mutations.
      // You might want to be more specific if you have many 'people' queries.
      queryClient.invalidateQueries({ queryKey: ['people'] });

      // Optionally, you can optimistically update the cache here
      // or directly update a specific query's data if you know the new person's details.
      // For example, if you have a query for a list of people:
      // queryClient.setQueryData(['people', /* relevant page/filters */], (oldData: any) => {
      //   // Add the new person to the list
      //   return oldData ? [...oldData, data.data] : [data.data];
      // });
    },
    onError: (error) => {
      // Handle error, e.g., show a toast notification
      console.error("Error creating person:", error);
    },
  });
};
