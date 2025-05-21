"use client";

import Link from "next/link";
import { Button } from "@lpg-ui/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@lpg-ui/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@lpg-ui/components/ui/avatar";
import { Search, Bell } from "lucide-react";
// import { useAuth } from "@/contexts/AuthContext"; // Assuming AuthContext provides user info and logout

export function UserMenu() {
  // const { user, logout } = useAuth(); // Placeholder for auth logic

  // Placeholder user data
  const user = {
    name: "Staff Member",
    email: "staff@chattprep.org",
    avatarUrl: undefined, // Replace with actual avatar URL if available
  };

  const getInitials = (name: string) => {
    const names = name.split(' ');
    if (names.length > 1) {
      return `${names[0][0]}${names[names.length - 1][0]}`.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  };

  const handleLogout = async () => {
    // await logout(); // Placeholder for actual logout
    // router.push('/login'); // Redirect after logout
    console.log("Logout clicked");
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" className="relative h-8 w-8 rounded-full">
          <Avatar className="h-8 w-8">
            {user.avatarUrl && <AvatarImage src={user.avatarUrl} alt={user.name} />}
            <AvatarFallback>{getInitials(user.name)}</AvatarFallback>
          </Avatar>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-56" align="end" forceMount>
        <DropdownMenuLabel className="font-normal">
          <div className="flex flex-col space-y-1">
            <p className="text-sm font-medium leading-none">{user.name}</p>
            <p className="text-xs leading-none text-muted-foreground">
              {user.email}
            </p>
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem>
          <Link href="/settings/profile">Profile</Link>
        </DropdownMenuItem>
        <DropdownMenuItem>
          <Link href="/settings">Settings</Link>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={handleLogout}>
          Log out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export function HeaderActions({ children }: { children: React.ReactNode }) {
  return (
    <div className="ml-auto flex items-center space-x-4">
      {children}
    </div>
  );
}

export function Header({ children }: { children: React.ReactNode }) {
  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-4 border-b bg-background px-4 md:px-6">
      {/* Placeholder for Mobile Nav Trigger if needed */}
      {/* <Button variant="outline" size="icon" className="shrink-0 md:hidden">
        <Menu className="h-5 w-5" />
        <span className="sr-only">Toggle navigation menu</span>
      </Button> */}
      
      {/* Placeholder for Global Search */}
      <div className="flex-1">
        {/* <form>
          <div className="relative">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Search..."
              className="w-full appearance-none bg-background pl-8 shadow-none md:w-2/3 lg:w-1/3"
            />
          </div>
        </form> */}
      </div>
      
      {children} {/* This is where HeaderActions will be rendered */}
    </header>
  );
}
