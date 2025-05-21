"use client";

import { useRouter, usePathname, useSearchParams } from "next/navigation";
import { useCallback, useMemo } from "react";

export function usePeopleFilters() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const currentFilter = useMemo(() => {
    return searchParams.get('filter') || 'all';
  }, [searchParams]);

  const searchTerm = useMemo(() => {
    return searchParams.get('query') || '';
  }, [searchParams]);

  const currentPage = useMemo(() => {
    return Number(searchParams.get('page')) || 1;
  }, [searchParams]);
  
  const sortBy = useMemo(() => {
    return searchParams.get('sortBy') || 'last_name_asc'; // Default sort
  }, [searchParams]);

  const setFilter = useCallback((filterValue: string) => {
    const params = new URLSearchParams(searchParams.toString());
    if (filterValue === 'all') {
      params.delete('filter');
    } else {
      params.set('filter', filterValue);
    }
    params.delete('page'); // Reset to page 1 when filter changes
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  }, [pathname, router, searchParams]);

  const setSearchTerm = useCallback((term: string) => {
    const params = new URLSearchParams(searchParams.toString());
    if (term) {
      params.set('query', term);
    } else {
      params.delete('query');
    }
    params.delete('page');
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  }, [pathname, router, searchParams]);

  const setPage = useCallback((page: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('page', String(page));
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  }, [pathname, router, searchParams]);

  const setSortBy = useCallback((sortValue: string) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('sortBy', sortValue);
    params.delete('page');
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  }, [pathname, router, searchParams]);

  return { 
    currentFilter, 
    setFilter,
    searchTerm,
    setSearchTerm,
    currentPage,
    setPage,
    sortBy,
    setSortBy,
    // rawSearchParams: searchParams // if needed for other params
  };
}
