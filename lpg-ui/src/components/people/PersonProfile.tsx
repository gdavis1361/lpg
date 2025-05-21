"use client";

import { Tabs, TabsList, TabsTrigger, TabsContent } from "@lpg-ui/components/ui/tabs";
import { ProfileHeader } from "./ProfileHeader"; // To be created
// import { DonorSummary } from "@/components/donor/DonorSummary"; // To be created
// import { MentorSummary } from "@/components/mentor/MentorSummary"; // To be created
// import { AlumniSummary } from "@/components/alumni/AlumniSummary"; // To be created
// import { TimelineView } from "@/components/timeline/TimelineView"; // To be created
// import { InteractionList } from "@/components/interactions/InteractionList"; // To be created
// import { RelationshipView } from "@/components/relationships/RelationshipView"; // To be created
// import { DonationList } from "@/components/donor/DonationList"; // To be created

// Define a more complete Person type, aligning with your data model
// This should eventually come from a shared types definition, perhaps from supabase types
interface Relationship {
  id: string;
  relationship_type: string;
  // Add other relationship fields like start_date, status, related_person_name etc.
}

interface Person {
  id: string;
  first_name: string;
  last_name: string;
  email?: string;
  phone?: string;
  relationships: Relationship[];
  // Add other fields like address, bio, tags, etc.
}

interface PersonProfileProps {
  person: Person;
}

// Placeholder components for now
const DonorSummary = ({ personId }: { personId: string }) => <div className="p-4 border rounded-md">Donor Summary for {personId} (Placeholder)</div>;
const MentorSummary = ({ personId }: { personId: string }) => <div className="p-4 border rounded-md">Mentor Summary for {personId} (Placeholder)</div>;
const AlumniSummary = ({ personId }: { personId: string }) => <div className="p-4 border rounded-md">Alumni Summary for {personId} (Placeholder)</div>;
const TimelineView = ({ entityId, entityType }: { entityId: string, entityType: string }) => <div className="p-4 border rounded-md">Timeline for {entityType} {entityId} (Placeholder)</div>;
const InteractionList = ({ personId }: { personId: string }) => <div className="p-4 border rounded-md">Interactions for {personId} (Placeholder)</div>;
const RelationshipView = ({ personId }: { personId: string }) => <div className="p-4 border rounded-md">Relationships for {personId} (Placeholder)</div>;
const DonationList = ({ personId }: { personId: string }) => <div className="p-4 border rounded-md">Donations for {personId} (Placeholder)</div>;


export function PersonProfile({ person }: PersonProfileProps) {
  const isDonor = person.relationships?.some(r => r.relationship_type === "donor");
  const isMentor = person.relationships?.some(r => r.relationship_type === "mentor");
  const isAlumni = person.relationships?.some(r => r.relationship_type === "alumni");
  // Add other role checks as needed

  const relationshipBadges = person.relationships.map(r => r.relationship_type) || [];

  return (
    <div className="space-y-4">
      <ProfileHeader 
        person={person} 
        badges={relationshipBadges}
      />
      
      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="overflow-x-auto whitespace-nowrap">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="timeline">Timeline</TabsTrigger>
          <TabsTrigger value="interactions">Interactions</TabsTrigger>
          <TabsTrigger value="relationships">Relationships</TabsTrigger>
          {isDonor && <TabsTrigger value="donations">Donations</TabsTrigger>}
          {/* Add more tabs based on roles if needed, e.g., Mentoring for mentors */}
        </TabsList>
        
        <TabsContent value="overview" className="mt-4">
          {/* Display general person details here */}
          <div className="p-4 border rounded-md mb-4">
            <h3 className="font-semibold mb-2">Details</h3>
            <p>Email: {person.email || "N/A"}</p>
            <p>Phone: {person.phone || "N/A"}</p>
            {/* Add more general details */}
          </div>
          {isDonor && <DonorSummary personId={person.id} />}
          {isMentor && <MentorSummary personId={person.id} />}
          {isAlumni && <AlumniSummary personId={person.id} />}
          {/* Add other role-specific summaries if they belong on the overview tab */}
        </TabsContent>
        
        <TabsContent value="timeline" className="mt-4">
          <TimelineView entityId={person.id} entityType="person" />
        </TabsContent>
        
        <TabsContent value="interactions" className="mt-4">
          <InteractionList personId={person.id} />
        </TabsContent>
        
        <TabsContent value="relationships" className="mt-4">
          <RelationshipView personId={person.id} />
        </TabsContent>
        
        {isDonor && (
          <TabsContent value="donations" className="mt-4">
            <DonationList personId={person.id} />
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
}
