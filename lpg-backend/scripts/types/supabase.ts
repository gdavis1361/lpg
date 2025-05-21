// Placeholder for Supabase database types
// Run 'npm run supabase:generate-types' to generate actual types

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      organizations: {
        Row: {
          id: string
          name: string
          description: string | null
          type: string | null
          metadata: Json | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string | null
          type?: string | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string | null
          type?: string | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
      }
      
      // Add other tables as needed
      // This is just a minimal placeholder to make the TypeScript compiler happy
      // Run the generator command to create a complete type definition
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
} 