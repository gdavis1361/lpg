"use client";

import { useRouter } from "next/navigation";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@lpg-ui/components/ui/table";
import { Avatar, AvatarFallback, AvatarImage } from "@lpg-ui/components/ui/avatar";
import { Badge } from "@lpg-ui/components/ui/badge";
import { Button } from "@lpg-ui/components/ui/button";
import { ArrowUpDown } from "lucide-react"; // For sortable headers later

// Mock Person type - replace with actual type from your data model
interface Person {
  id: string;
  first_name: string;
  last_name: string;
  relationships: Array<{ id: string; relationship_type: string }>;
  last_interaction_date?: string;
  relationship_health?: string;
  // Add other fields like email, phone, etc., as needed for the table
}

interface PeopleTableProps {
  data: Person[];
  isLoading?: boolean;
  onRowClick?: (person: Person) => void;
  // sortColumn?: keyof Person; // Enable when Person type is more defined
  // sortDirection?: 'asc' | 'desc';
  // onSort?: (column: keyof Person) => void;
  // Add props for pagination control later
}

// Helper component for relationship health badge
function HealthIndicator({ health }: { health?: string }) {
  if (!health || health === "unknown") {
    return <Badge variant="outline">Unknown</Badge>;
  }
  const variantMap: { [key: string]: "default" | "secondary" | "destructive" | "outline" } = {
    excellent: "default", // Assuming 'default' is a positive color like green
    good: "secondary",    // Assuming 'secondary' is a mild positive color
    average: "outline",   // Neutral
    concerning: "destructive",
  };
  return <Badge variant={variantMap[health] || "outline"}>{health.charAt(0).toUpperCase() + health.slice(1)}</Badge>;
}

// Helper to get variant for relationship type badge
function getRelationshipVariant(type: string): "default" | "secondary" | "destructive" | "outline" {
  const variants: { [key: string]: "default" | "secondary" | "destructive" | "outline" } = {
    donor: "default", // e.g., primary color
    mentor: "secondary",
    alumni: "outline", // Using outline for alumni as an example
    staff: "outline",
    // Add other types as needed
  };
  return variants[type] || "outline";
}

export function PeopleTable({ 
  data, 
  isLoading, 
  onRowClick,
  // sortColumn, 
  // sortDirection, 
  // onSort 
}: PeopleTableProps) {
  const router = useRouter();

  if (isLoading) {
    // Basic loading state, can be replaced with a skeleton table
    return <div className="text-center py-8 text-muted-foreground">Loading table data...</div>;
  }

  if (!data || data.length === 0) {
    return <div className="text-center py-8 text-muted-foreground">No people found.</div>;
  }

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            {/* Example for sortable header, implement onSort when ready */}
            {/* <TableHead onClick={() => onSort?.('first_name')}>
              Name <ArrowUpDown className="ml-2 h-4 w-4 inline" />
            </TableHead> */}
            <TableHead>Name</TableHead>
            <TableHead>Relationship(s)</TableHead>
            <TableHead>Last Interaction</TableHead>
            <TableHead>Health</TableHead>
            <TableHead className="text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.map((person) => (
            <TableRow 
              key={person.id} 
              onClick={() => onRowClick?.(person)}
              className={onRowClick ? "cursor-pointer" : ""}
            >
              <TableCell>
                <div className="flex items-center gap-3">
                  <Avatar className="h-9 w-9">
                    {/* <AvatarImage src={person.avatarUrl} alt={`${person.first_name} ${person.last_name}`} /> */}
                    <AvatarFallback>
                      {person.first_name?.[0]?.toUpperCase()}
                      {person.last_name?.[0]?.toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <div className="grid gap-0.5">
                    <span className="font-medium">
                      {person.first_name} {person.last_name}
                    </span>
                    {/* <span className="text-xs text-muted-foreground">{person.email}</span> */}
                  </div>
                </div>
              </TableCell>
              <TableCell>
                <div className="flex flex-wrap gap-1">
                  {person.relationships.map((rel) => (
                    <Badge key={rel.id} variant={getRelationshipVariant(rel.relationship_type)}>
                      {rel.relationship_type.charAt(0).toUpperCase() + rel.relationship_type.slice(1)}
                    </Badge>
                  ))}
                  {person.relationships.length === 0 && <span className="text-xs text-muted-foreground">-</span>}
                </div>
              </TableCell>
              <TableCell>
                {person.last_interaction_date
                  ? new Date(person.last_interaction_date).toLocaleDateString()
                  : <span className="text-xs text-muted-foreground">-</span>}
              </TableCell>
              <TableCell>
                <HealthIndicator health={person.relationship_health} />
              </TableCell>
              <TableCell className="text-right">
                <Button variant="ghost" size="sm" onClick={() => router.push(`/people/${person.id}`)}>
                  View
                </Button>
                {/* Add other actions like Edit, Delete (perhaps in a DropdownMenu) */}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
