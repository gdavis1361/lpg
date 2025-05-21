"use client";

import { usePeopleFilters } from "@/hooks/usePeopleFilters"; // Import the hook
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@lpg-ui/components/ui/select";
import { Badge } from "@lpg-ui/components/ui/badge";

interface PeopleFilterProps {
  // activeFilter prop is no longer needed as the hook provides it
}

export function PeopleFilter({}: PeopleFilterProps) { // Removed activeFilter from props
  const { currentFilter, setFilter } = usePeopleFilters();

  return (
    <div className="mb-4 flex flex-col gap-4 md:flex-row md:items-center">
      <Select value={currentFilter} onValueChange={setFilter}> {/* Use currentFilter and setFilter from hook */}
        <SelectTrigger className="w-full md:w-[200px]">
          <SelectValue placeholder="Filter by relationship" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All People</SelectItem>
          <SelectItem value="donor">Donors</SelectItem>
          <SelectItem value="mentor">Mentors</SelectItem>
          <SelectItem value="alumni">Alumni</SelectItem>
          {/* Add other filterable relationship types here if needed */}
        </SelectContent>
      </Select>

      <div className="flex flex-wrap gap-2">
        {currentFilter === "donor" && (
          <>
            <Badge variant="outline">Donors View</Badge>
            {/* These could be sub-filters or quick links in a real implementation */}
            {/* <Badge variant="secondary">Recent Gifts</Badge>
            <Badge variant="secondary">Cultivation</Badge> */}
          </>
        )}
        {currentFilter === "mentor" && (
          <>
            <Badge variant="outline">Mentors View</Badge>
            {/* <Badge variant="secondary">Active Mentees</Badge>
            <Badge variant="secondary">Needs Matching</Badge> */}
          </>
        )}
        {currentFilter === "alumni" && (
          <>
            <Badge variant="outline">Alumni View</Badge>
            {/* <Badge variant="secondary">Recent Graduates</Badge>
            <Badge variant="secondary">College</Badge>
            <Badge variant="secondary">Career</Badge> */}
          </>
        )}
      </div>
    </div>
  );
}
