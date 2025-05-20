// src/components/RelationshipHealthDashboard.tsx
'use client'; // Indicates this is a Client Component

import React, { useEffect, useState } from 'react';
import { useSupabaseClient } from '@supabase/auth-helpers-react';
// Assuming you have a UI library or will create these components:
// import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'; 
// import { Badge } from '@/components/ui/badge';
// import { Progress } from '@/components/ui/progress';

// Placeholder types - replace with your actual types, possibly generated from Supabase schema
interface MentorRelationshipHealthData {
  relationship_id: string;
  mentor_first_name: string | null;
  mentor_last_name: string | null;
  student_first_name: string | null;
  student_last_name: string | null;
  health_status: 'healthy' | 'behind_required_milestones' | 'inactive' | string; // Add other possible statuses
  // Add other fields from your mentor_relationship_health_mv view as needed
  relationship_years?: number;
  total_interactions?: number;
  recent_interactions_90_days?: number;
  total_milestones_achieved?: number;
  required_milestones_achieved_count?: number;
}

interface HealthCounts {
  healthy: number;
  behind_required_milestones: number;
  inactive: number;
  [key: string]: number; // For any other statuses
}

// Placeholder UI components - replace with your actual UI library components
// These are simplified versions. Your actual components will have more props and styling.
const Card: React.FC<{ children: React.ReactNode, className?: string }> = ({ children, className }) => (
  <div className={`border rounded-lg shadow-xs p-6 bg-white ${className}`}>{children}</div>
);
const CardHeader: React.FC<{ children: React.ReactNode, className?: string }> = ({ children, className }) => (
  <div className={`mb-4 ${className}`}>{children}</div>
);
const CardTitle: React.FC<{ children: React.ReactNode, className?: string }> = ({ children, className }) => (
  <h3 className={`text-xl font-semibold ${className}`}>{children}</h3>
);
const CardContent: React.FC<{ children: React.ReactNode, className?: string }> = ({ children, className }) => (
  <div className={className}>{children}</div>
);

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'destructive' | 'outline' | 'secondary'; // Example variants
  colorScheme?: 'green' | 'yellow' | 'red' | 'blue' | 'gray'; // Custom prop for color
  className?: string;
}
const Badge: React.FC<BadgeProps> = ({ children, colorScheme, className }) => {
  let bgColor = 'bg-gray-100 text-gray-800'; // Default
  if (colorScheme === 'green') bgColor = 'bg-green-100 text-green-800';
  if (colorScheme === 'yellow') bgColor = 'bg-yellow-100 text-yellow-800';
  if (colorScheme === 'red') bgColor = 'bg-red-100 text-red-800';
  if (colorScheme === 'blue') bgColor = 'bg-blue-100 text-blue-800';
  
  return <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${bgColor} ${className}`}>{children}</span>;
};

interface ProgressProps {
  value: number; // Percentage value (0-100)
  colorScheme?: 'green' | 'yellow' | 'red' | 'blue';
  className?: string;
}
const Progress: React.FC<ProgressProps> = ({ value, colorScheme, className }) => {
  let barColor = 'bg-blue-600';
  if (colorScheme === 'green') barColor = 'bg-green-500';
  if (colorScheme === 'yellow') barColor = 'bg-yellow-500';
  if (colorScheme === 'red') barColor = 'bg-red-500';

  return (
    <div className={`w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700 ${className}`}>
      <div className={`${barColor} h-2.5 rounded-full`} style={{ width: `${value}%` }}></div>
    </div>
  );
};


export default function RelationshipHealthDashboard() {
  const supabase = useSupabaseClient(); // Ensure this hook is correctly set up in your Supabase context
  const [loading, setLoading] = useState(true);
  const [mentorData, setMentorData] = useState<MentorRelationshipHealthData[]>([]);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    async function fetchMentorRelationships() {
      setLoading(true);
      setError(null);
      
      // Fetch mentor relationships health data from the materialized view
      const { data, error: fetchError } = await supabase
        .from('mentor_relationship_health_mv') // Use the materialized view
        .select('*'); // Select all columns or specify needed ones
      
      if (fetchError) {
        console.error('Error fetching mentor relationship health data:', fetchError);
        setError(fetchError.message);
        setMentorData([]);
      } else {
        setMentorData(data || []);
      }
      
      setLoading(false);
    }
    
    fetchMentorRelationships();
  }, [supabase]); // Re-run effect if supabase client instance changes
  
  if (loading) {
    return <div className="p-4 text-center">Loading relationship health data...</div>;
  }
  
  if (error) {
    return <div className="p-4 text-center text-red-600">Error loading data: {error}</div>;
  }

  if (mentorData.length === 0) {
    return <div className="p-4 text-center">No mentor relationship data available.</div>;
  }
  
  const healthCounts = mentorData.reduce((acc, rel) => {
    const status = rel.health_status || 'unknown';
    acc[status] = (acc[status] || 0) + 1;
    return acc;
  }, {} as HealthCounts);

  const totalRelationships = mentorData.length;
  const healthyPercentage = totalRelationships > 0 ? ((healthCounts.healthy || 0) / totalRelationships * 100) : 0;
  
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-4">
      <Card className="md:col-span-2 lg:col-span-1">
        <CardHeader>
          <CardTitle>Mentor Relationship Health Overview</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-wrap justify-around items-center gap-2 mb-4">
            <Badge colorScheme="green" className="text-sm">
              Healthy: {healthCounts.healthy || 0}
            </Badge>
            <Badge colorScheme="yellow" className="text-sm">
              Behind: {healthCounts.behind_required_milestones || 0}
            </Badge>
            <Badge colorScheme="red" className="text-sm">
              Inactive: {healthCounts.inactive || 0}
            </Badge>
            {Object.keys(healthCounts).filter(k => !['healthy', 'behind_required_milestones', 'inactive'].includes(k)).map(statusKey => (
              <Badge key={statusKey} colorScheme="gray" className="text-sm">
                {statusKey.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}: {healthCounts[statusKey]}
              </Badge>
            ))}
          </div>
          
          <div className="space-y-1">
            <div className="flex justify-between text-sm font-medium">
              <span>Overall Health</span>
              <span>{healthyPercentage.toFixed(0)}% Healthy</span>
            </div>
            <Progress value={healthyPercentage} colorScheme="green" />
          </div>
          
          <p className="text-xs text-gray-500">
            Total Mentor Relationships: {totalRelationships}
          </p>
        </CardContent>
      </Card>
      
      <Card className="md:col-span-2 lg:col-span-2">
        <CardHeader>
          <CardTitle>Relationship Details</CardTitle>
        </CardHeader>
        <CardContent>
          {mentorData.length > 0 ? (
            <div className="space-y-3 max-h-96 overflow-y-auto">
              {mentorData.map(rel => (
                <div key={rel.relationship_id} className="p-3 border rounded-md flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 hover:bg-gray-50 transition-colors">
                  <div className="flex-grow">
                    <div className="font-semibold text-sm">
                      {rel.student_first_name || 'N/A'} {rel.student_last_name || 'N/A'}
                    </div>
                    <div className="text-xs text-gray-600">
                      Mentor: {rel.mentor_first_name || 'N/A'} {rel.mentor_last_name || 'N/A'}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      Years: {rel.relationship_years ?? 'N/A'} | Interactions: {rel.total_interactions ?? 'N/A'} ({rel.recent_interactions_90_days ?? 0} recent)
                    </div>
                  </div>
                  <div className="flex-shrink-0 mt-2 sm:mt-0">
                    <Badge 
                      colorScheme={
                        rel.health_status === 'healthy' ? 'green' : 
                        rel.health_status === 'behind_required_milestones' ? 'yellow' :
                        rel.health_status === 'inactive' ? 'red' : 'gray'
                      }
                    >
                      {rel.health_status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-gray-500">No relationships to display.</p>
          )}
        </CardContent>
      </Card>
      
      {/* You can add more cards here for other metrics or visualizations */}
    </div>
  );
}
