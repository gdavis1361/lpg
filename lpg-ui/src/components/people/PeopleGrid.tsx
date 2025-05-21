"use client";

import { useRouter } from "next/navigation";
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@lpg-ui/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@lpg-ui/components/ui/avatar";
import { Badge } from "@lpg-ui/components/ui/badge";
import { Button } from "@lpg-ui/components/ui/button";

// Mock Person type - ensure this matches the one in PeopleTable and PeopleView
interface Person {
  id: string;
  first_name: string;
  last_name: string;
  relationships: Array<{ id: string; relationship_type: string }>;
  last_interaction_date?: string;
  relationship_health?: string;
  // email?: string; // Example additional field
}

interface PeopleGridProps {
  data: Person[];
  isLoading?: boolean;
  onItemClick?: (person: Person) => void;
}

// Helper component for relationship health badge (can be shared or defined locally)
function HealthIndicator({ health }: { health?: string }) {
  if (!health || health === "unknown") {
    return <Badge variant="outline">Unknown</Badge>;
  }
  const variantMap: { [key: string]: "default" | "secondary" | "destructive" | "outline" } = {
    excellent: "default",
    good: "secondary",
    average: "outline",
    concerning: "destructive",
  };
  return <Badge variant={variantMap[health] || "outline"}>{health.charAt(0).toUpperCase() + health.slice(1)}</Badge>;
}

function getRelationshipVariant(type: string): "default" | "secondary" | "destructive" | "outline" {
  const variants: { [key: string]: "default" | "secondary" | "destructive" | "outline" } = {
    donor: "default",
    mentor: "secondary",
    alumni: "outline",
    staff: "outline",
  };
  return variants[type] || "outline";
}

export function PeopleGrid({ data, isLoading, onItemClick }: PeopleGridProps) {
  const router = useRouter();

  if (isLoading) {
    // Basic loading state, can be replaced with a skeleton grid
    return <div className="text-center py-8 text-muted-foreground">Loading grid data...</div>;
  }

  if (!data || data.length === 0) {
    return <div className="text-center py-8 text-muted-foreground">No people found.</div>;
  }

  return (
    <div className="@container"> {/* Outermost div is the container */}
      <div className="grid grid-cols-1 gap-4 @sm:grid-cols-2 @lg:grid-cols-3 @xl:grid-cols-4"> {/* Grid styling on the child */}
        {data.map((person) => (
          <Card 
            key={person.id} 
            className={`flex flex-col ${onItemClick ? "cursor-pointer hover:shadow-lg transition-shadow" : ""}`}
            onClick={() => onItemClick?.(person)}
          >
          <CardHeader className="flex flex-row items-center gap-3 pb-2">
            <Avatar className="h-12 w-12">
              {/* <AvatarImage src={person.avatarUrl} alt={`${person.first_name} ${person.last_name}`} /> */}
              <AvatarFallback>
                {person.first_name?.[0]?.toUpperCase()}
                {person.last_name?.[0]?.toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div className="grid gap-0.5">
              <CardTitle className="text-lg">
                {person.first_name} {person.last_name}
              </CardTitle>
              {/* <CardDescription className="text-xs">{person.email || "No email"}</CardDescription> */}
            </div>
          </CardHeader>
          <CardContent className="flex-1 space-y-2 py-2">
            <div className="flex flex-wrap gap-1">
              {person.relationships.map((rel) => (
                <Badge key={rel.id} variant={getRelationshipVariant(rel.relationship_type)}>
                  {rel.relationship_type.charAt(0).toUpperCase() + rel.relationship_type.slice(1)}
                </Badge>
              ))}
              {person.relationships.length === 0 && <Badge variant="outline">No Relationships</Badge>}
            </div>
            <div className="text-sm text-muted-foreground">
              Last Interaction: {person.last_interaction_date ? new Date(person.last_interaction_date).toLocaleDateString() : "-"}
            </div>
            <div>
              Health: <HealthIndicator health={person.relationship_health} />
            </div>
          </CardContent>
          <CardFooter>
            <Button variant="outline" size="sm" className="w-full" onClick={() => router.push(`/people/${person.id}`)}>
              View Profile
            </Button>
          </CardFooter>
        </Card>
      ))}
      </div> {/* This div for grid closes here */}
    </div> // This is the @container div closing
  );
}
