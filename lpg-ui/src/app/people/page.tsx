import React from "react"; // Added React for Suspense
import { PeopleView } from "@/components/people/PeopleView";
// import { getPeople } from "@/lib/api/data-access"; // Placeholder for actual data fetching

// Mock data fetching function - replace with actual implementation
async function getPeople(params: { filter?: string, searchTerm?: string, sortBy?: string, page?: number }) {
  console.log("Fetching people with params:", params);
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 500));
  
  const allPeople = [
    { id: "1", first_name: "John", last_name: "Doe", relationships: [{ id: "r1", relationship_type: "mentor" }], last_interaction_date: "2024-05-01", relationship_health: "good" },
    { id: "2", first_name: "Jane", last_name: "Smith", relationships: [{ id: "r2", relationship_type: "donor" }], last_interaction_date: "2024-04-15", relationship_health: "excellent" },
    { id: "3", first_name: "Alice", last_name: "Johnson", relationships: [{ id: "r3", relationship_type: "alumni" }], last_interaction_date: "2024-05-10", relationship_health: "average" },
    { id: "4", first_name: "Bob", last_name: "Brown", relationships: [{ id: "r4", relationship_type: "mentor" }, {id: "r5", relationship_type: "donor"}], last_interaction_date: "2024-03-20", relationship_health: "concerning" },
    { id: "5", first_name: "Charlie", last_name: "Davis", relationships: [{ id: "r6", relationship_type: "staff" }], last_interaction_date: "2024-05-15", relationship_health: "unknown" },
  ];

  if (params.filter && params.filter !== "all") {
    return allPeople.filter(p => p.relationships.some(r => r.relationship_type === params.filter));
  }
  return allPeople;
}


export default async function PeoplePage({
  searchParams,
}: {
  searchParams?: {
    filter?: string;
    query?: string;
    page?: string;
    sortBy?: string;
  };
}) {
  const filter = searchParams?.filter || "all";
  const currentPage = Number(searchParams?.page) || 1;
  const searchTerm = searchParams?.query || "";
  const sortBy = searchParams?.sortBy || "last_name_asc";

  // TODO: Pass searchTerm, sortBy, currentPage to getPeople when implemented
  const people = await getPeople({ filter }); 
  // const totalPages = await getPeoplePages({ filter, query: searchTerm }); // Placeholder

  // Placeholder for skeleton component
  const PeopleListSkeleton = () => <div className="p-4 text-center text-muted-foreground">Loading people...</div>;

  return (
    <React.Suspense fallback={<PeopleListSkeleton />}>
      <PeopleView initialData={people} />
    </React.Suspense>
  );
}
