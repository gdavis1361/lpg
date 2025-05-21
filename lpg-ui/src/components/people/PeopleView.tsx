"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardHeader, CardTitle, CardContent } from "@lpg-ui/components/ui/card";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@lpg-ui/components/ui/tabs";
import { Button } from "@lpg-ui/components/ui/button";
import { PlusIcon } from "lucide-react";
import { PeopleTable } from "./PeopleTable";
import { PeopleGrid } from "./PeopleGrid";
import { PeopleFilter } from "./PeopleFilter";

// Mock Person type - replace with actual type from your data model
interface Person {
  id: string;
  first_name: string;
  last_name: string;
  relationships: Array<{ id: string; relationship_type: string }>;
  last_interaction_date?: string;
  relationship_health?: string;
}

interface PeopleViewProps {
  initialData: Person[];
  // activeFilter: string; // No longer needed, PeopleFilter uses the hook
  // totalPages: number; // For pagination later
  // currentPage: number; // For pagination later
}

export function PeopleView({ initialData }: PeopleViewProps) { // Removed activeFilter
  const [viewMode, setViewMode] = useState("table");
  const router = useRouter();
  
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>People</CardTitle>
          <div>
            <Button onClick={() => router.push("/people/new")}>
              <PlusIcon className="mr-2 h-4 w-4" />
              <span>Add Person</span>
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <PeopleFilter /> {/* Removed activeFilter prop */}
          
          <Tabs value={viewMode} onValueChange={setViewMode} className="w-full">
            <TabsList className="grid w-full grid-cols-2 md:w-[200px]">
              <TabsTrigger value="table">Table</TabsTrigger>
              <TabsTrigger value="grid">Grid</TabsTrigger>
            </TabsList>
            
            <TabsContent value="table" className="mt-4">
              <PeopleTable data={initialData} />
            </TabsContent>
            
            <TabsContent value="grid" className="mt-4">
              <PeopleGrid data={initialData} />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}
