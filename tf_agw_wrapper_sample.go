#################################################################
### This is only snippest of code 
#################################################################
package main

import "fmt"
import "encoding/json"
import "io/ioutil"	
import "log"
import "os"
import "strconv"
import "flag"



func main() {

    //Variable initialization for inputs
    var backend_address_pools, backend_http_settings, http_listeners, frontend_port_settings []interface{}
    ....
    ....
    //Global variable to merge inputs from each config file
    var global_rec = make(map[string]interface{})

    //Variable to collect frontend ports from http_listener sections 
    var frontend_ports = make(map[string]string)

    //Config file directory
    var src_dir string
    flag.StringVar(&src_dir, "src_dir", "", "Source Config Dir")
    flag.Parse()
    src_config_dir := "./"+src_dir+"/"

    //Process all files from config dir
    files, err := os.Open(src_config_dir)
    if err != nil {
        log.Fatal(err)
    }
    defer files.Close()

    list, _ := files.Readdirnames(0)

    //Iterate through each file
    for _, name := range list {
        fl_name := src_config_dir+name
        fmt.Println("Processing File",fl_name)

        //Variables to capture and validate/map names references in config file
        var bkd_pools_lst = make(map[string]string)
        ....
        ....
        var probe_names_lst = make(map[string]string)
        ...
        ...

        //Variable to get data from config file
        var info map[string]interface{}
        file, _ := ioutil.ReadFile(fl_name)
        err1 := json.Unmarshal([]byte(file), &info)
        if err1 != nil {
            log.Fatal("Error: File JSON Format Incorrect")
        }

        //Formulate application name to be used to define naming standards
        app_prefix := info["app_id"].(string)+info["env"].(string)

        //Process backend_address_pool
        app_bkd_prefix := app_prefix+"bkdpool_"
        for _, rec := range info["backend_address_pools"].([]interface{}) {
            new_rec := make(map[string]interface{})
            cur_rec := rec.(map[string]interface{})
            for key, val := range cur_rec {
                new_rec[key] = val
                pool_number := fmt.Sprintf("%v",val)
                if key == "number" {
                    new_rec["name"] = app_bkd_prefix+pool_number 
                    bkd_pools_lst[pool_number] = app_bkd_prefix+pool_number
                }
            }
            backend_address_pools = append(backend_address_pools,new_rec)
        }
      
      .....
      ....
      ....
        //Process probe_configs
        if info["probe_configs"] != nil {
            if len(info["probe_configs"].([]interface{})) != len(probe_names_lst) {
                log.Fatal("Error: Number of probe config name reference in backend_http_settings and probe_configs does not match")
            }
            for _, rec := range info["probe_configs"].([]interface{}) {
                new_rec := make(map[string]interface{})
                cur_rec := rec.(map[string]interface{})

                for key, val := range cur_rec {
                    if key == "name" {
                        t_val, ok := probe_names_lst[val.(string)]
                        if ok {
                            new_rec[key] = t_val
                        } else {
                            log.Fatal("Error: Probe name does not match with name references in backend_http_settings")
                        } 
                    } else {
                        new_rec[key] = val
                    }
                }
                probe_configs = append(probe_configs,new_rec)
            }
        } else {
            if len(probe_names_lst) != 0 {
                log.Fatal("Error: backend_http_settings section reference probe name for which details are not provided via probe_configs")
            }
        }
    }
    //All files processing completed and merge for each section completed
	  //Create record to prepare final data for TF app gateway module
    global_rec["backend_address_pools"] = backend_address_pools
    global_rec["backend_http_settings"] = backend_http_settings
    global_rec["http_listeners"] = http_listeners
    if basic_request_routing_rules == nil {
        basic_request_routing_rules = make([]interface{},0)
    }
    global_rec["basic_request_routing_rules"] = basic_request_routing_rules
    ....
    ....
    ....
    if probe_configs == nil {
        probe_configs = make([]interface{},0)
    }
    global_rec["probe_configs"] = probe_configs
    ...
    ...
    ...
	 
	  //Print the final record if 'debug' env variable is set
    out, err := json.Marshal(global_rec)
    if err != nil {
        log.Fatal(err)
    }
    if os.Getenv("debug") == "True" { 
        fmt.Println(string(out))
	  }
	
	//Write the record to file
	fmt.Println("Writing merge config data to ./app_gw_inputs.tfvars.json")
	op_file, err := json.MarshalIndent(global_rec, "", " ")
	if err != nil {
		log.Fatal(err)
	}
	err = ioutil.WriteFile("./app_gw_inputs.tfvars.json", op_file, 0644)
	if err != nil {
		log.Fatal(err)
	}
}
