"use client";

import Image from "next/image"; // Import next/image
import { Badge } from "@lpg-ui/components/ui/badge";
import { Button } from "@lpg-ui/components/ui/button";
import { Edit3Icon } from "lucide-react"; // Or another appropriate edit icon
import { useRouter } from "next/navigation";
import { Avatar, AvatarFallback } from "@lpg-ui/components/ui/avatar"; // Keep AvatarFallback for no image case

// Define a Person type, ensure it's consistent with PersonProfile
interface Person {
  id: string;
  first_name: string;
  last_name: string;
  email?: string;
  avatar_url?: string; // Added avatar_url
  // Add other fields that might be displayed in the header
}

interface ProfileHeaderProps {
  person: Person;
  badges: string[]; // Array of relationship types or other status strings
}

function getRelationshipVariant(type: string): "default" | "secondary" | "destructive" | "outline" {
  const variants: { [key: string]: "default" | "secondary" | "destructive" | "outline" } = {
    donor: "default",
    mentor: "secondary",
    alumni: "outline",
    staff: "outline",
    // Add other types as needed
  };
  return variants[type] || "outline";
}

export function ProfileHeader({ person, badges }: ProfileHeaderProps) {
  const router = useRouter();

  const handleEdit = () => {
    router.push(`/people/${person.id}/edit`);
  };

  return (
    <div className="flex flex-col items-start gap-4 rounded-lg border bg-card p-6 shadow-sm md:flex-row md:items-center md:justify-between">
      <div className="flex items-center gap-4">
        <div className="relative h-20 w-20 overflow-hidden rounded-full border">
          {person.avatar_url ? (
            <Image
              src={person.avatar_url}
              alt={`${person.first_name} ${person.last_name}`}
              fill
              sizes="80px" // h-20 w-20 is 80px
              className="object-cover"
              priority={false}
            />
          ) : (
            <Avatar className="h-full w-full"> {/* Use shadcn Avatar as container for Fallback */}
              <AvatarFallback className="text-2xl">
                {person.first_name?.[0]?.toUpperCase()}
                {person.last_name?.[0]?.toUpperCase()}
              </AvatarFallback>
            </Avatar>
          )}
        </div>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            {person.first_name} {person.last_name}
          </h1>
          {person.email && (
            <p className="text-sm text-muted-foreground">{person.email}</p>
          )}
          <div className="mt-2 flex flex-wrap gap-2">
            {badges.map((badgeText, index) => (
              <Badge key={index} variant={getRelationshipVariant(badgeText.toLowerCase())}>
                {badgeText.charAt(0).toUpperCase() + badgeText.slice(1)}
              </Badge>
            ))}
          </div>
        </div>
      </div>
      <div>
        <Button variant="outline" onClick={handleEdit}>
          <Edit3Icon className="mr-2 h-4 w-4" />
          Edit Profile
        </Button>
        {/* Add other action buttons here, e.g., Log Interaction, Add Relationship */}
      </div>
    </div>
  );
}
