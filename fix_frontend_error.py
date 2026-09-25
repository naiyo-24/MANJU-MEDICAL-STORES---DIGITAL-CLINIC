import re

service_file = '/Users/hypothticoder/MANJU-MEDICAL-STORES---DIGITAL-CLINIC/lib/services/inventory_service.dart'
content = open(service_file).read()

old_catch = """    } catch (e) {
      throw Exception('Error adding medicine: $e');
    }"""

new_catch = """    } catch (e) {
      if (e is DioException && e.response != null && e.response!.data is Map && e.response!.data['detail'] != null) {
        throw Exception(e.response!.data['detail']);
      }
      throw Exception(e.toString());
    }"""

if old_catch in content:
    # Need to make sure DioException is known, though it probably is since it's printed.
    content = content.replace(old_catch, new_catch)
    open(service_file, 'w').write(content)
    print("Updated inventory_service.dart successfully")
else:
    print("Could not find the catch block in inventory_service.dart")
