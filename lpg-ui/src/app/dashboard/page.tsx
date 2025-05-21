import { getPeople } from '../../lib/api/data-access';
import Link from 'next/link';

export default async function DashboardPage() {
  const { data: people, error } = await getPeople(1, 10);
  
  if (error) {
    return (
      <div className="p-8">
        <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
        <div className="p-4 bg-red-50 text-red-700 rounded-md">
          Error loading data: {error.message}
        </div>
      </div>
    );
  }
  
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      
      <div className="mb-8">
        <h2 className="text-xl font-semibold mb-2">People</h2>
        {people && people.length > 0 ? (
          <div className="bg-white shadow rounded-lg overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Email
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Graduation Year
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {people.map((person) => (
                  <tr key={person.id}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {person.avatar_url && (
                          <div className="flex-shrink-0 h-10 w-10 mr-3">
                            <img
                              className="h-10 w-10 rounded-full"
                              src={person.avatar_url}
                              alt={`${person.first_name} ${person.last_name}`}
                            />
                          </div>
                        )}
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {person.first_name} {person.last_name}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-500">{person.email || 'No email'}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-500">
                        {person.graduation_year || 'N/A'}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <Link
                        href={`/people/${person.id}`}
                        className="text-blue-600 hover:text-blue-900 mr-4"
                      >
                        View
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="bg-gray-50 p-4 rounded-md text-gray-700">
            No people found in the system.
          </div>
        )}
      </div>
      
      <div className="mt-6 flex space-x-4">
        <Link
          href="/people/new"
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Add Person
        </Link>
        <Link
          href="/relationships/new"
          className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
        >
          Create Relationship
        </Link>
      </div>
    </div>
  );
} 