import { PersonProfile } from "@/components/people/PersonProfile";
// import { getPerson } from "@/lib/api/data-access"; // Placeholder

// Mock data fetching function - replace with actual implementation
async function getPerson(id: string) {
  console.log("Fetching person with id:", id);
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 300));
  
  // Find person from a mock list or return a default mock person
  const allPeople = [
    { id: "1", first_name: "John", last_name: "Doe", relationships: [{ id: "r1", relationship_type: "mentor" }], email: "john.doe@example.com", phone: "555-1234" },
    { id: "2", first_name: "Jane", last_name: "Smith", relationships: [{ id: "r2", relationship_type: "donor" }], email: "jane.smith@example.com", phone: "555-5678" },
    { id: "3", first_name: "Alice", last_name: "Johnson", relationships: [{ id: "r3", relationship_type: "alumni" }], email: "alice.j@example.com", phone: "555-8765" },
  ];
  const person = allPeople.find(p => p.id === id);
  
  if (!person) {
    // Return a generic mock or throw an error/redirect in a real app
    return { id, first_name: "Not Found", last_name: "", relationships: [], email: "", phone: "" };
  }
  return person;
}

export default async function PersonPage({ params }: { params: { id: string } }) {
  if (!params.id) {
    // Handle case where id is not provided, though Next.js routing should prevent this
    // Could redirect or show a "not found" message
    return <div>Person ID is missing.</div>;
  }
  const person = await getPerson(params.id);

  if (!person || person.first_name === "Not Found") {
    // In a real app, you might use notFound() from next/navigation
    return <div>Person not found.</div>;
  }

  return <PersonProfile person={person} />;
}
